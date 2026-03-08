class RemindersController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_action :authenticate_user!
  before_action :set_reminder, only: [:show, :update, :destroy, :complete]

  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error

  def index
    @reminders = current_user.reminders
    render json: @reminders.map { |reminder| convert_reminder_to_local_time(reminder) }
  end

  def show
    render json: convert_reminder_to_local_time(@reminder)
  end

  def create
    reminder_params = parse_and_validate_reminder_params

    @reminder = current_user.reminders.new(reminder_params.except(:user_ids))

    ActiveRecord::Base.transaction do
      if @reminder.save
        create_invitations(reminder_params[:user_ids], @reminder) if reminder_params[:user_ids].present?
        handle_creation_notifications(@reminder)
        handle_scheduled_notifications(@reminder) if @reminder.due_date > Time.current

        # Broadcast to tagged users — rescued so Redis errors never rollback the transaction
        begin
          reminder_params[:user_ids]&.each do |user_id|
            ActionCable.server.broadcast("notifications_#{user_id}", {
              message: 'You have a new task assigned!'
            })
          end
        rescue => e
          Rails.logger.warn "ActionCable broadcast failed (non-fatal): #{e.message}"
        end

        render json: {
          status: 'success',
          message: 'Reminder created successfully',
          reminder: convert_reminder_to_local_time(@reminder)
        }, status: :created
      else
        render json: {
          status: 'error',
          message: 'Failed to create reminder',
          errors: @reminder.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    handle_exception(e, :unprocessable_entity)
  rescue StandardError => e
    handle_exception(e, :internal_server_error)
  end

  def update
    if @reminder.update(reminder_params)
      render json: {
        status: 'success',
        message: 'Reminder updated successfully',
        reminder: convert_reminder_to_local_time(@reminder)
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to update reminder',
        errors: @reminder.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @reminder.destroy
    head :no_content
  end

  def complete
    if @reminder.update(completed: true)
      CompletedTask.create(
        title:       @reminder.title,
        description: @reminder.description,
        due_date:    @reminder.due_date,
        user:        current_user
      )
      render json: {
        status: 'success',
        message: 'Reminder completed successfully',
        reminder: convert_reminder_to_local_time(@reminder)
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to complete reminder',
        errors: @reminder.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  # ── Params ──────────────────────────────────────────────────────────────────

  def parse_and_validate_reminder_params
    reminder_params = params.require(:reminder).permit(
      :title, :description, :due_date, :duration, :priority,
      :location, :occasion, :label, :is_special_event,
      :repeat_interval, :repeat_interval_unit,
      :custom_interval_value, :custom_interval_unit,
      :note_id, :calendar_id,
      user_ids: []
    )
    reminder_params[:due_date] = DateTime.parse(reminder_params[:due_date]) if reminder_params[:due_date].present?
    reminder_params
  rescue ArgumentError => e
    raise ActiveRecord::RecordInvalid, "Invalid due_date format: #{e.message}"
  end

  def reminder_params
    params.require(:reminder).permit(
      :title, :description, :due_date, :duration, :priority,
      :location, :occasion, :label, :is_special_event,
      :repeat_interval, :repeat_interval_unit,
      :custom_interval_value, :custom_interval_unit,
      :note_id, :calendar_id,
      user_ids: []
    )
  end

  # ── Invitations ─────────────────────────────────────────────────────────────

  def create_invitations(user_ids, reminder)
    user_ids.each do |user_id|
      invitation = Invitation.create!(
        reminder_id: reminder.id,
        user_id:     user_id,
        status:      'pending',
        sender_id:   current_user.id
      )
      handle_invitation_result(invitation, user_id)
    end
  end

  def handle_invitation_result(invitation, user_id)
    if invitation.persisted?
      send_invitation_email(invitation)
      broadcast_invitation_notification(invitation, user_id)
    else
      Rails.logger.error "Failed to create invitation for User #{user_id}: #{invitation.errors.full_messages.join(', ')}"
    end
  end

  def send_invitation_email(invitation)
    InvitationMailer.invitation_email(invitation).deliver_now
    Rails.logger.info "Invitation email sent to User #{invitation.user_id}"
  end

  def broadcast_invitation_notification(invitation, user_id)
    ActionCable.server.broadcast "notifications_#{user_id}", {
      type: 'invitation',
      data: invitation.as_json(include: :reminder)
    }
    Rails.logger.info "Invitation notification broadcasted to User #{user_id}"
  rescue => e
    Rails.logger.warn "Invitation broadcast failed (non-fatal): #{e.message}"
  end

  # ── Notifications ────────────────────────────────────────────────────────────

  def handle_creation_notifications(reminder)
    send_creation_notification(reminder)
  end

  def handle_scheduled_notifications(reminder)
    send_notifications(reminder) if reminder.due_date > Time.current
  end

  def send_creation_notification(reminder)
    time_remaining = distance_of_time_in_words(Time.current, reminder.due_date)
    message = "Created #{reminder.title} which is due in #{time_remaining}"

    notification = Notification.create(
      user:     reminder.user,
      reminder: reminder,
      message:  message,
      schedule: 'immediate'
    )

    if notification.persisted?
      Rails.logger.info "Creation notification created: #{notification.id}"
      send_email_notification(notification)
      notify_user(reminder.user)
    else
      Rails.logger.error "Creation notification failed: #{notification.errors.full_messages}"
    end
  end

  def send_notifications(reminder)
    notification_times = [
      { time: reminder.due_date - 24.hours,   schedule: '24_hours'    },
      { time: reminder.due_date - 1.hour,     schedule: '1_hour'      },
      { time: reminder.due_date - 30.minutes, schedule: '30_minutes'  },
      { time: reminder.due_date - 5.minutes,  schedule: '5_minutes'   },
    ]

    next_notification = notification_times.find { |nt| nt[:time] > Time.current }

    return unless next_notification

    parts   = next_notification[:schedule].split('_')
    message = "#{reminder.title} starts in #{parts.first} #{parts.last}"

    # NOTE: Do NOT set created_at manually — Rails protects that column
    notification = Notification.create(
      user:     reminder.user,
      reminder: reminder,
      message:  message,
      schedule: next_notification[:schedule]
    )

    if notification.persisted?
      Rails.logger.info "Scheduled notification created: #{notification.id}"
      send_email_notification(notification)
      notify_user(reminder.user)
    else
      Rails.logger.error "Scheduled notification failed: #{notification.errors.full_messages}"
    end
  end

  def send_email_notification(notification)
    user    = notification.user
    subject = "Notification: #{notification.reminder.title}"
    message = notification.message
    NotificationMailer.notification_email(user, subject, message).deliver_now
  rescue => e
    Rails.logger.error "Email notification failed: #{e.message}"
  end

  # FIX: rescued so Redis being down never rolls back a saved reminder
  def notify_user(user)
    ActionCable.server.broadcast "notifications_#{user.id}", {
      message: 'You have a new notification!'
    }
  rescue => e
    Rails.logger.warn "ActionCable notify_user failed (non-fatal): #{e.message}"
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  def set_reminder
    @reminder = current_user.reminders.find_by(id: params[:id])
    render json: { error: 'Reminder not found or unauthorized' }, status: :not_found unless @reminder
  end

  def convert_reminder_to_local_time(reminder)
    return nil if reminder.nil?
    reminder.attributes.merge(
      'due_date' => reminder.due_date&.in_time_zone('Africa/Nairobi')&.strftime('%Y-%m-%d %H:%M:%S')
    )
  end

  def handle_exception(exception, status)
    Rails.logger.error "#{exception.class.name}: #{exception.message}"
    render json: { error: exception.message }, status: status
  end

  def handle_parse_error(exception)
    render json: { error: "Error parsing request parameters: #{exception.message}" }, status: :bad_request
  end
end

# class RemindersController < ApplicationController
#   include ActionView::Helpers::DateHelper

#   before_action :authenticate_user!
#   before_action :set_reminder, only: [:show, :update, :destroy, :complete]

#   rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error

#   def index
#     @reminders = current_user.reminders
#     render json: @reminders.map { |reminder| convert_reminder_to_local_time(reminder) }
#   end

#   def show
#     render json: convert_reminder_to_local_time(@reminder)
#   end

 
#   def create
#   reminder_params = parse_and_validate_reminder_params

#   @reminder = current_user.reminders.new(reminder_params.except(:user_ids))

#   ActiveRecord::Base.transaction do
#     if @reminder.save
#       create_invitations(reminder_params[:user_ids], @reminder) if reminder_params[:user_ids].present?
#       handle_creation_notifications(@reminder)
#       handle_scheduled_notifications(@reminder) if @reminder.due_date > Time.current

#       # ✅ FIX: Wrap broadcast in rescue so Redis errors don't rollback the transaction
#       begin
#         reminder_params[:user_ids]&.each do |user_id|
#           ActionCable.server.broadcast("notifications_#{user_id}", {
#             message: 'You have a new task assigned!'
#           })
#         end
#       rescue => e
#         Rails.logger.warn "ActionCable broadcast failed (non-fatal): #{e.message}"
#       end

#       render json: {
#         status: 'success',
#         message: 'Reminder created successfully',
#         reminder: convert_reminder_to_local_time(@reminder)
#       }, status: :created
#     else
#       render json: {
#         status: 'error',
#         message: 'Failed to create reminder',
#         errors: @reminder.errors.full_messages
#       }, status: :unprocessable_entity
#     end
#   end
# rescue ArgumentError, ActiveRecord::RecordInvalid => e
#   handle_exception(e, :unprocessable_entity)
# rescue StandardError => e
#   handle_exception(e, :internal_server_error)
# end
  

#   def update
#     if @reminder.update(reminder_params)
#       render json: { status: 'success', message: 'Reminder updated successfully', reminder: convert_reminder_to_local_time(@reminder) }
#     else
#       render json: { status: 'error', message: 'Failed to update reminder', errors: @reminder.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   def destroy
#     @reminder.destroy
#     head :no_content
#   end

#   def complete
#     if @reminder.update(completed: true)
#       CompletedTask.create(title: @reminder.title, description: @reminder.description, due_date: @reminder.due_date, user: current_user)
#       render json: { status: 'success', message: 'Reminder completed successfully', reminder: convert_reminder_to_local_time(@reminder) }
#     else
#       render json: { status: 'error', message: 'Failed to complete reminder', errors: @reminder.errors }, status: :unprocessable_entity
#     end
#   end

#   private

#   def parse_and_validate_reminder_params
#   reminder_params = params.require(:reminder).permit(
#     :title, :due_date, :priority, :location, :description,
#     :duration, :occasion, :is_special_event,          # ← ADD THESE
#     :repeat_interval, :repeat_interval_unit,           # ← ADD THESE
#     :label, :note_id, :calendar_id,                   # ← ADD THESE
#     user_ids: []
#   )
#   reminder_params[:due_date] = DateTime.parse(reminder_params[:due_date]) if reminder_params[:due_date].present?
#   reminder_params
# rescue ArgumentError => e
#   raise ActiveRecord::RecordInvalid, "Invalid due_date format: #{e.message}"
# end

#   def create_invitations(user_ids, reminder)
#     user_ids.each do |user_id|
#       invitation = Invitation.create!(
#         reminder_id: reminder.id,
#         user_id: user_id,
#         status: 'pending',
#         sender_id: current_user.id # Assign sender_id here
#       )
#       handle_invitation_result(invitation, user_id)
#     end
#   end
  

#   def handle_invitation_result(invitation, user_id)
#     if invitation.persisted?
#       send_invitation_email(invitation)
#       broadcast_invitation_notification(invitation, user_id)
#     else
#       Rails.logger.error "Failed to create invitation for User #{user_id}: #{invitation.errors.full_messages.join(', ')}"
#     end
#   end

#   def send_invitation_email(invitation)
#     InvitationMailer.invitation_email(invitation).deliver_now
#     Rails.logger.info "Invitation email sent to User #{invitation.user_id}"
#   end

#   def broadcast_invitation_notification(invitation, user_id)
#     ActionCable.server.broadcast "notifications_#{user_id}", {
#       type: "invitation",
#       data: invitation.as_json(include: :reminder)
#     }
#     Rails.logger.info "Invitation notification broadcasted to User #{user_id}"
#   end

#   def handle_creation_notifications(reminder)
#     send_creation_notification(reminder)
#   end

#   def handle_scheduled_notifications(reminder)
#     send_notifications(reminder) if reminder.due_date > Time.current
#   end

#   def handle_exception(exception, status)
#     Rails.logger.error "#{exception.class.name}: #{exception.message}"
#     render json: { error: exception.message }, status: status
#   end

#   def set_reminder
#     @reminder = current_user.reminders.find_by(id: params[:id])
#     render json: { error: 'Reminder not found or unauthorized' }, status: :not_found unless @reminder
#   end

#   # def reminder_params
#   #   params.require(:reminder).permit(:title, :description, :is_special_event, :occasion, :due_date, :repeat_interval, :repeat_interval_unit, :location, :priority, :calendar_id, :duration, user_ids: [])
#   # end
#   def reminder_params
#     params.require(:reminder).permit(:title, :description, :is_special_event, :occasion, :due_date,
#                                      :repeat_interval, :repeat_interval_unit, :location, :priority,
#                                      :calendar_id, :duration, :custom_interval_value, :custom_interval_unit,
#                                      user_ids: [])
#   end
  
  
#   def send_creation_notification(reminder)
#     time_remaining = distance_of_time_in_words(Time.current, reminder.due_date)
#     message = "Created #{reminder.title} which is due in #{time_remaining}"

#     notification = Notification.create(
#       user: reminder.user,
#       reminder: reminder,
#       message: message,
#       schedule: 'immediate'
#     )
#     logger.info "Creation notification created: #{notification.inspect}" if notification.persisted?
#     logger.error "Creation notification creation failed: #{notification.errors.full_messages}" unless notification.persisted?

#     send_email_notification(notification)
#     notify_user(reminder.user)
#   end

#   def send_notifications(reminder)
#     notification_times = [
#       { time: reminder.due_date - 24.hours, schedule: "24_hours" },
#       { time: reminder.due_date - 1.hour, schedule: "1_hour" },
#       { time: reminder.due_date - 30.minutes, schedule: "30_minutes" },
#       { time: reminder.due_date - 5.minutes, schedule: "5_minutes" }
#     ]

#     next_notification = notification_times.find { |nt| nt[:time] > Time.current }

#     if next_notification
#       notification = Notification.create(
#         user: reminder.user,
#         reminder: reminder,
#         message: "#{reminder.title} starts in #{next_notification[:schedule].split('_').first} #{next_notification[:schedule].split('_').last}",
#         schedule: next_notification[:schedule],
#         created_at: next_notification[:time]
#       )
#       logger.info "Notification created: #{notification.inspect}" if notification.persisted?
#       logger.error "Notification creation failed: #{notification.errors.full_messages}" unless notification.persisted?

#       send_email_notification(notification)
#       notify_user(reminder.user)
#     end
#   end

#   def send_email_notification(notification)
#     user = notification.user
#     subject = "Notification: #{notification.reminder.title}"
#     message = notification.message

#     NotificationMailer.notification_email(user, subject, message).deliver_now

#     { status: 'success', message: 'Email notification sent successfully' }
#   end

#   def notify_user(user)
#     ActionCable.server.broadcast "notifications_#{user.id}", { message: 'You have a new task assigned!' }
#   end

#   def convert_reminder_to_local_time(reminder)
#     reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S')) unless reminder.nil?
#   end

#   def handle_parse_error(exception)
#     render json: { error: "Error parsing request parameters: #{exception.message}" }, status: :bad_request
#   end
# end
