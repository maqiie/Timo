
# class RemindersController < ApplicationController
#   include ActionView::Helpers::DateHelper
#   rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error


#   before_action :authenticate_user!
#   before_action :set_reminder, only: [:show, :update, :destroy, :complete]


#   def add_user
#     @reminder = Reminder.find(params[:id])
#     user = User.find(params[:user_id])
#     relationship_category = params[:relationship_category].to_sym

#     if @reminder.add_user(user, relationship_category)
#       redirect_to @reminder, notice: "User added successfully."
#     else
#       redirect_to @reminder, alert: "Failed to add user."
#     end
#   end


#   def index
#     @reminders = current_user.reminders
#     render json: @reminders.map { |reminder| convert_reminder_to_local_time(reminder) }
#   end

#   def index_by_date
#     if params[:date].nil?
#       render json: { error: "Date parameter is missing" }, status: :bad_request
#       return
#     end
  
#     date = Date.parse(params[:date])
#     reminders = Reminder.where(due_date: date.beginning_of_day..date.end_of_day)
#     render json: reminders
#   rescue ArgumentError => e
#     render json: { error: e.message }, status: :bad_request
#   end
  

#   def show
#     render json: convert_reminder_to_local_time(@reminder)
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Reminder not found' }, status: :not_found
#   end
 



#   def create
#     reminder_params = params.require(:reminder).permit(:title, :due_date, :priority, :location, :description, :duration, user_ids: [])
  
#     # Parse due_date string into DateTime object
#     begin
#       reminder_params[:due_date] = DateTime.parse(reminder_params[:due_date])
#     rescue ArgumentError => e
#       render json: { status: 'error', message: 'Invalid due date format', error: e.message }, status: :unprocessable_entity
#       return
#     end
  
#     # Debug: Log current_user
#     Rails.logger.debug "Current User: #{current_user.inspect}"
  
#     @reminder = current_user.reminders.new(reminder_params.except(:user_ids))
  
#     Reminder.transaction do
#       if @reminder.save
#         Rails.logger.debug "Reminder saved successfully: #{@reminder.inspect}"
  
#         user_ids = reminder_params[:user_ids] || []
#         user_ids.each do |user_id|
#           user = User.find_by(id: user_id)
#           unless user
#             Rails.logger.error "User not found with ID #{user_id}"
#             next
#           end
  
#           reminder_user = ReminderUser.new(reminder_id: @reminder.id, user_id: user_id, relationship_category: :friend)
#           if reminder_user.save
#             Rails.logger.info "ReminderUser created successfully for User #{user_id}"
#           else
#             Rails.logger.error "Failed to create ReminderUser for User #{user_id}: #{reminder_user.errors.full_messages.join(', ')}"
#           end
#         end
  
#         send_creation_notification(@reminder)
#         send_notifications(@reminder) if @reminder.due_date > Time.current
  
#         render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }, status: :created
#       else
#         Rails.logger.error "Reminder save failed: #{@reminder.errors.full_messages.join(', ')}"
#         render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors.full_messages }, status: :unprocessable_entity
#       end
#     rescue ActiveRecord::RecordInvalid => e
#       Rails.logger.error "ActiveRecord::RecordInvalid: #{e.message}"
#       render json: { error: e.message }, status: :unprocessable_entity
#     rescue StandardError => e
#       Rails.logger.error "StandardError: #{e.message}"
#       render json: { error: e.message }, status: :internal_server_error
#     end
#   end
  
  
  
#   def valid_task_creation?(user_ids, due_date)
#     return false if user_ids.empty?

#     due_datetime = DateTime.parse(due_date)
#     due_day = due_datetime.strftime("%A")
#     due_time = due_datetime.strftime("%H:%M").to_time

#     user_ids.all? do |user_id|
#       relationship = UserRelationship.find_by(user_id: current_user.id, related_user_id: user_id)
#       next false unless relationship

#       case relationship.relationship_type
#       when 'family'
#         true
#       when 'friend'
#         !['Sunday', 'Public Holiday'].include?(due_day)
#       when 'colleague'
#         !['Saturday', 'Sunday', 'Public Holiday'].include?(due_day) &&
#           due_time.between?('08:00'.to_time, '19:00'.to_time)
#       else
#         false
#       end
#     end
#   end

  
 
  
  
#   def reminder_params
#     params.require(:reminder).permit(:title, :due_date, :priority, :location, :description, :duration, user_ids: [])
#   end
  
#   def note_params
#     params.require(:note).permit(:content) if params[:note].present?
#   end
  
  
 

#   def special_events
#     @special_events = current_user.reminders.where(is_special_event: true)
#     render json: @special_events
#   end

#   def update
#     logger.info "Received parameters: #{params.inspect}"
#     if @reminder.update(reminder_params)
#       render json: { status: 'success', message: 'Reminder updated successfully', reminder: convert_reminder_to_local_time(@reminder) }
#     else
#       logger.error "Reminder update failed: #{@reminder.errors.full_messages}"
#       render json: { status: 'error', message: 'Failed to update reminder', errors: @reminder.errors }, status: :unprocessable_entity
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

#   def set_reminder
#     @reminder = current_user.reminders.find_by(id: params[:id])
#     render json: { error: 'Reminder not found or unauthorized' }, status: :not_found unless @reminder
#   end

#   def reminder_params
#     params.require(:reminder).permit(:title, :description, :is_special_event, :occasion, :due_date, :repeat_interval, :repeat_interval_unit, :location, :priority, :calendar_id, :duration, user_ids: [])
#   end
  

#   def note_params
#     params.require(:note).permit(:content) if params[:note].present?
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
#   end


#   def send_notifications(reminder)
#     notification_times = [
#       { time: reminder.due_date - 24.hours, schedule: "24_hours" },
#       { time: reminder.due_date - 1.hour, schedule: "1_hour" },
#       { time: reminder.due_date - 30.minutes, schedule: "30_minutes" },
#       { time: reminder.due_date - 5.minutes, schedule: "5_minutes" }
#     ]
  
#     # Find the next relevant notification time
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
  
#       send_email_notification(notification) # Send email for the next notification
#     end
#   end
  

 
#   def send_email_notification(notification)
#     user = notification.user
#     subject = "Notification: #{notification.reminder.title}"
#     message = notification.message
  
#     # Send email using the NotificationMailer
#     NotificationMailer.notification_email(user, subject, message).deliver_now
  
#     # No need to render JSON response here, just return success status
#     { status: 'success', message: 'Email notification sent successfully' }
#   end
  

#   def convert_reminder_to_local_time(reminder)
#     return reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S')) unless reminder.nil?
#     nil
#   end
#   def handle_parse_error(exception)
#     render json: { error: "Error parsing request parameters: #{exception.message}" }, status: :bad_request
#   end

# end
# class RemindersController < ApplicationController
#   include ActionView::Helpers::DateHelper

#   before_action :authenticate_user!
#   before_action :set_reminder, only: [:show, :update, :destroy, :complete]

#   rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error

#   def index
#     @reminders = current_user.reminders
#     render json: @reminders.map { |reminder| convert_reminder_to_local_time(reminder) }
#   end

#   def index_by_date
#     if params[:date].blank?
#       render json: { error: "Date parameter is missing" }, status: :bad_request
#       return
#     end

#     begin
#       date = Date.parse(params[:date])
#       reminders = Reminder.where(due_date: date.beginning_of_day..date.end_of_day)
#       render json: reminders
#     rescue ArgumentError => e
#       render json: { error: e.message }, status: :bad_request
#     end
#   end

#   def show
#     render json: convert_reminder_to_local_time(@reminder)
#   end

#   def create
#     reminder_params = params.require(:reminder).permit(:title, :due_date, :priority, :location, :description, :duration, user_ids: [])

#     begin
#       reminder_params[:due_date] = DateTime.parse(reminder_params[:due_date])
#     rescue ArgumentError => e
#       render json: { status: 'error', message: 'Invalid due date format', error: e.message }, status: :unprocessable_entity
#       return
#     end

#     @reminder = current_user.reminders.new(reminder_params.except(:user_ids))

#     if @reminder.save
#       user_ids = reminder_params[:user_ids] || []
#       user_ids.each do |user_id|
#         user = User.find_by(id: user_id)
#         next unless user

#         invitation_params = { user_id: user_id, reminder_id: @reminder.id, status: 'pending' }
#         create_invitation(invitation_params)  # Create invitation for each tagged user
#       end

#       send_creation_notification(@reminder)
#       send_notifications(@reminder) if @reminder.due_date > Time.current

#       render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }, status: :created
#     else
#       render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors.full_messages }, status: :unprocessable_entity
#     end
#   end


#   def update
#     if @reminder.update(reminder_params)
#       render json: { status: 'success', message: 'Reminder updated successfully', reminder: convert_reminder_to_local_time(@reminder) }
#     else
#       render json: { status: 'error', message: 'Failed to update reminder', errors: @reminder.errors }, status: :unprocessable_entity
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

#   def add_user
#     user = User.find_by(id: params[:user_id])
#     relationship_category = params[:relationship_category].to_sym

#     if user && @reminder.add_user(user, relationship_category)
#       redirect_to @reminder, notice: "User added successfully."
#     else
#       redirect_to @reminder, alert: "Failed to add user."
#     end
#   end

#   def special_events
#     @special_events = current_user.reminders.where(is_special_event: true)
#     render json: @special_events
#   end

#   private
# # This method creates an invitation for a tagged user
#   def create_invitation(invitation_params)
#     Invitation.create(invitation_params)
#     # Optionally, send an email notification here if needed
#   end
#   def create_invitation(invitation_params)
#     invitations_controller = InvitationsController.new
#     invitations_controller.request = request
#     invitations_controller.response = response

#     invitations_controller.create(invitation: invitation_params)  # Pass params as :invitation key
#   end
#   def set_reminder
#     @reminder = current_user.reminders.find_by(id: params[:id])
#     render json: { error: 'Reminder not found or unauthorized' }, status: :not_found unless @reminder
#   end

#   def reminder_params
#     params.require(:reminder).permit(:title, :description, :is_special_event, :occasion, :due_date, :repeat_interval, :repeat_interval_unit, :location, :priority, :calendar_id, :duration, user_ids: [])
#   end

#   def send_notification_and_email(user, reminder)
#     notification = Notification.create(
#       user: user,
#       reminder: reminder,
#       message: "#{reminder.title} has been assigned to you",
#       schedule: "immediate"
#     )
#     logger.info "User notification created: #{notification.inspect}" if notification.persisted?
#     logger.error "User notification creation failed: #{notification.errors.full_messages}" unless notification.persisted?

#     InvitationMailer.with(user: user, reminder: reminder).invitation_email.deliver_later

#     notify_user(user) # Notify user via Action Cable
#   end

#   def notify_user(user)
#     ActionCable.server.broadcast "notifications_#{user.id}", { message: 'You have a new task assigned!' }
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
#     end
#   end

#   def send_email_notification(notification)
#     user = notification.user
#     subject = "Notification: #{notification.reminder.title}"
#     message = notification.message

#     NotificationMailer.notification_email(user, subject, message).deliver_now

#     { status: 'success', message: 'Email notification sent successfully' }
#   end

#   def convert_reminder_to_local_time(reminder)
#     reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S')) unless reminder.nil?
#   end

#   def handle_parse_error(exception)
#     render json: { error: "Error parsing request parameters: #{exception.message}" }, status: :bad_request
#   end
# end

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

  # def create
  #   reminder_params = parse_and_validate_reminder_params

  #   @reminder = current_user.reminders.new(reminder_params.except(:user_ids))

  #   begin
  #     ActiveRecord::Base.transaction do
  #       if @reminder.save
  #         create_invitations(reminder_params[:user_ids], @reminder) if reminder_params[:user_ids].present?
  #         handle_creation_notifications(@reminder)
  #         handle_scheduled_notifications(@reminder) if @reminder.due_date > Time.current

  #         render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }, status: :created
  #       else
  #         render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors.full_messages }, status: :unprocessable_entity
  #       end
  #     end
  #   rescue ArgumentError, ActiveRecord::RecordInvalid => e
  #     handle_exception(e, :unprocessable_entity)
  #   rescue StandardError => e
  #     handle_exception(e, :internal_server_error)
  #   end
  # end
  def create
    reminder_params = parse_and_validate_reminder_params
  
    @reminder = current_user.reminders.new(reminder_params.except(:user_ids))
  
    begin
      ActiveRecord::Base.transaction do
        if @reminder.save
          create_invitations(reminder_params[:user_ids], @reminder) if reminder_params[:user_ids].present?
          handle_creation_notifications(@reminder)
          handle_scheduled_notifications(@reminder) if @reminder.due_date > Time.current
  
          # Broadcast notification
          reminder_params[:user_ids].each do |user_id|
            ActionCable.server.broadcast("notifications_#{user_id}", {
              message: 'You have a new task assigned!'
            })
          end if reminder_params[:user_ids].present?
  
          render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }, status: :created
        else
          render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors.full_messages }, status: :unprocessable_entity
        end
      end
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      handle_exception(e, :unprocessable_entity)
    rescue StandardError => e
      handle_exception(e, :internal_server_error)
    end
  end
  

  def update
    if @reminder.update(reminder_params)
      render json: { status: 'success', message: 'Reminder updated successfully', reminder: convert_reminder_to_local_time(@reminder) }
    else
      render json: { status: 'error', message: 'Failed to update reminder', errors: @reminder.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @reminder.destroy
    head :no_content
  end

  def complete
    if @reminder.update(completed: true)
      CompletedTask.create(title: @reminder.title, description: @reminder.description, due_date: @reminder.due_date, user: current_user)
      render json: { status: 'success', message: 'Reminder completed successfully', reminder: convert_reminder_to_local_time(@reminder) }
    else
      render json: { status: 'error', message: 'Failed to complete reminder', errors: @reminder.errors }, status: :unprocessable_entity
    end
  end

  private

  def parse_and_validate_reminder_params
    reminder_params = params.require(:reminder).permit(:title, :due_date, :priority, :location, :description, :duration, user_ids: [])
    reminder_params[:due_date] = DateTime.parse(reminder_params[:due_date]) if reminder_params[:due_date].present?
    reminder_params
  rescue ArgumentError => e
    raise ActiveRecord::RecordInvalid, "Invalid due_date format: #{e.message}"
  end

  def create_invitations(user_ids, reminder)
    user_ids.each do |user_id|
      invitation = Invitation.create!(
        reminder_id: reminder.id,
        user_id: user_id,
        status: 'pending',
        sender_id: current_user.id # Assign sender_id here
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
      type: "invitation",
      data: invitation.as_json(include: :reminder)
    }
    Rails.logger.info "Invitation notification broadcasted to User #{user_id}"
  end

  def handle_creation_notifications(reminder)
    send_creation_notification(reminder)
  end

  def handle_scheduled_notifications(reminder)
    send_notifications(reminder) if reminder.due_date > Time.current
  end

  def handle_exception(exception, status)
    Rails.logger.error "#{exception.class.name}: #{exception.message}"
    render json: { error: exception.message }, status: status
  end

  def set_reminder
    @reminder = current_user.reminders.find_by(id: params[:id])
    render json: { error: 'Reminder not found or unauthorized' }, status: :not_found unless @reminder
  end

  def reminder_params
    params.require(:reminder).permit(:title, :description, :is_special_event, :occasion, :due_date, :repeat_interval, :repeat_interval_unit, :location, :priority, :calendar_id, :duration, user_ids: [])
  end

  def send_creation_notification(reminder)
    time_remaining = distance_of_time_in_words(Time.current, reminder.due_date)
    message = "Created #{reminder.title} which is due in #{time_remaining}"

    notification = Notification.create(
      user: reminder.user,
      reminder: reminder,
      message: message,
      schedule: 'immediate'
    )
    logger.info "Creation notification created: #{notification.inspect}" if notification.persisted?
    logger.error "Creation notification creation failed: #{notification.errors.full_messages}" unless notification.persisted?

    send_email_notification(notification)
    notify_user(reminder.user)
  end

  def send_notifications(reminder)
    notification_times = [
      { time: reminder.due_date - 24.hours, schedule: "24_hours" },
      { time: reminder.due_date - 1.hour, schedule: "1_hour" },
      { time: reminder.due_date - 30.minutes, schedule: "30_minutes" },
      { time: reminder.due_date - 5.minutes, schedule: "5_minutes" }
    ]

    next_notification = notification_times.find { |nt| nt[:time] > Time.current }

    if next_notification
      notification = Notification.create(
        user: reminder.user,
        reminder: reminder,
        message: "#{reminder.title} starts in #{next_notification[:schedule].split('_').first} #{next_notification[:schedule].split('_').last}",
        schedule: next_notification[:schedule],
        created_at: next_notification[:time]
      )
      logger.info "Notification created: #{notification.inspect}" if notification.persisted?
      logger.error "Notification creation failed: #{notification.errors.full_messages}" unless notification.persisted?

      send_email_notification(notification)
      notify_user(reminder.user)
    end
  end

  def send_email_notification(notification)
    user = notification.user
    subject = "Notification: #{notification.reminder.title}"
    message = notification.message

    NotificationMailer.notification_email(user, subject, message).deliver_now

    { status: 'success', message: 'Email notification sent successfully' }
  end

  def notify_user(user)
    ActionCable.server.broadcast "notifications_#{user.id}", { message: 'You have a new task assigned!' }
  end

  def convert_reminder_to_local_time(reminder)
    reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S')) unless reminder.nil?
  end

  def handle_parse_error(exception)
    render json: { error: "Error parsing request parameters: #{exception.message}" }, status: :bad_request
  end
end
