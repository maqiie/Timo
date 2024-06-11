
# class RemindersController < ApplicationController
#   before_action :authenticate_user!
#   before_action :set_reminder, only: [:show, :update, :destroy, :complete]

#   def index
#     @reminders = current_user.reminders
#     render json: @reminders.map { |reminder| convert_reminder_to_local_time(reminder) }
#   end

#   def show
#     render json: convert_reminder_to_local_time(@reminder)
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Reminder not found' }, status: :not_found
#   end

#   def create
#     @reminder = current_user.reminders.new(reminder_params)
#     @note = current_user.notes.create(note_params) if note_params.present?

#     if @reminder.save
#       @reminder.update(note: @note) if @note&.persisted?
#       send_notifications(@reminder) if @reminder.due_date > Time.current
#       logger.info "Reminder created: #{@reminder.inspect}"
#       render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }, status: :created
#     else
#       logger.error "Reminder creation failed: #{@reminder.errors.full_messages}"
#       render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
#     end
#   end

#   def special_events
#     @special_events = current_user.reminders.where(is_special_event: true)
#     render json: @special_events
#   end
  
  
  
  
  
#   def convert_reminder_to_local_time(reminder)
#     return reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S')) unless reminder.nil?
#     nil
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
#     params.require(:reminder).permit(:title, :description, :is_special_event,:occasion, :due_date, :repeat_interval, :repeat_interval_unit, :location, :priority, :calendar_id, :duration)
#   end
  

#   def note_params
#     params.require(:note).permit(:content) if params[:note].present?
#   end

  
  
#   def send_notifications(reminder)
#     notification_times = [
#       { time: reminder.due_date - 24.hours, schedule: "24_hours" },
#       { time: reminder.due_date - 1.hour, schedule: "1_hour" },
#       { time: reminder.due_date - 30.minutes, schedule: "30_minutes" },
#       { time: reminder.due_date - 5.minutes, schedule: "5_minutes" },
#       { time: reminder.due_date, schedule: "" }
#     ]
  
#     notification_times.each do |nt|
#       if nt[:time] > Time.current
#         notification = Notification.create(
#           user: reminder.user,
#           reminder: reminder,
#           message: "#{reminder.title} starts in #{nt[:schedule].split('_').first} #{nt[:schedule].split('_').last}",
#           schedule: nt[:schedule],
#           created_at: nt[:time]
#         )
#         logger.info "Notification created: #{notification.inspect}" if notification.persisted?
#         logger.error "Notification creation failed: #{notification.errors.full_messages}" unless notification.persisted?
        
#         send_email_notification(notification) # Send email for each notification
#       end
#     end
#   end
  


# def send_email_notification(notification)
#   user_email = notification.user.email
#   subject = "Notification: #{notification.reminder.title}"
#   message = notification.message

#   # Send email using the NotificationMailer
#   NotificationMailer.notification_email(user_email, subject, message).deliver_now

#   # No need to render JSON response here, just return success status
#   { status: 'success', message: 'Email notification sent successfully' }
# end

  

#   # def convert_reminder_to_local_time(reminder)
#   #   reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S'))
#   # end
# end
class RemindersController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_action :authenticate_user!
  before_action :set_reminder, only: [:show, :update, :destroy, :complete]

  def index
    @reminders = current_user.reminders
    render json: @reminders.map { |reminder| convert_reminder_to_local_time(reminder) }
  end

  def show
    render json: convert_reminder_to_local_time(@reminder)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Reminder not found' }, status: :not_found
  end

  def create
    @reminder = current_user.reminders.new(reminder_params)
    @note = current_user.notes.create(note_params) if note_params.present?

    if @reminder.save
      @reminder.update(note: @note) if @note&.persisted?
      send_creation_notification(@reminder)
      send_notifications(@reminder) if @reminder.due_date > Time.current
      logger.info "Reminder created: #{@reminder.inspect}"
      render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }, status: :created
    else
      logger.error "Reminder creation failed: #{@reminder.errors.full_messages}"
      render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
    end
  end

  def special_events
    @special_events = current_user.reminders.where(is_special_event: true)
    render json: @special_events
  end

  def update
    logger.info "Received parameters: #{params.inspect}"
    if @reminder.update(reminder_params)
      render json: { status: 'success', message: 'Reminder updated successfully', reminder: convert_reminder_to_local_time(@reminder) }
    else
      logger.error "Reminder update failed: #{@reminder.errors.full_messages}"
      render json: { status: 'error', message: 'Failed to update reminder', errors: @reminder.errors }, status: :unprocessable_entity
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

  def set_reminder
    @reminder = current_user.reminders.find_by(id: params[:id])
    render json: { error: 'Reminder not found or unauthorized' }, status: :not_found unless @reminder
  end

  def reminder_params
    params.require(:reminder).permit(:title, :description, :is_special_event, :occasion, :due_date, :repeat_interval, :repeat_interval_unit, :location, :priority, :calendar_id, :duration)
  end

  def note_params
    params.require(:note).permit(:content) if params[:note].present?
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
  end

  def send_notifications(reminder)
    notification_times = [
      { time: reminder.due_date - 24.hours, schedule: "24_hours" },
      { time: reminder.due_date - 1.hour, schedule: "1_hour" },
      { time: reminder.due_date - 30.minutes, schedule: "30_minutes" },
      { time: reminder.due_date - 5.minutes, schedule: "5_minutes" },
      { time: reminder.due_date, schedule: "" }
    ]

    notification_times.each do |nt|
      if nt[:time] > Time.current
        notification = Notification.create(
          user: reminder.user,
          reminder: reminder,
          message: "#{reminder.title} starts in #{nt[:schedule].split('_').first} #{nt[:schedule].split('_').last}",
          schedule: nt[:schedule],
          created_at: nt[:time]
        )
        logger.info "Notification created: #{notification.inspect}" if notification.persisted?
        logger.error "Notification creation failed: #{notification.errors.full_messages}" unless notification.persisted?

        send_email_notification(notification) # Send email for each notification
      end
    end
  end

  # def send_email_notification(notification)
  #   user_email = notification.user.email
  #   subject = "Notification: #{notification.reminder.title}"
  #   message = notification.message

  #   # Send email using the NotificationMailer
  #   NotificationMailer.notification_email(user_email, subject, message).deliver_now

  #   # No need to render JSON response here, just return success status
  #   { status: 'success', message: 'Email notification sent successfully' }
  # end
  def send_email_notification(notification)
    user = notification.user
    subject = "Notification: #{notification.reminder.title}"
    message = notification.message
  
    # Send email using the NotificationMailer
    NotificationMailer.notification_email(user, subject, message).deliver_now
  
    # No need to render JSON response here, just return success status
    { status: 'success', message: 'Email notification sent successfully' }
  end
  

  def convert_reminder_to_local_time(reminder)
    return reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S')) unless reminder.nil?
    nil
  end
end
