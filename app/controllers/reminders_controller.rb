
# class RemindersController < ApplicationController
#   before_action :authenticate_user!
#   before_action :set_reminder, only: [:show, :update, :destroy]

#   def index
#     @reminders = current_user.reminders
#     render json: @reminders.map { |reminder| convert_reminder_to_local_time(reminder) }
#   end

#   def show
#     render json: convert_reminder_to_local_time(@reminder)
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Reminder not found' }, status: :not_found
#   end

#   # def create
#   #   @reminder = current_user.reminders.new(reminder_params)
    
#   #   if note_params.present?
#   #     @note = current_user.notes.create(note_params)
#   #     @reminder.note = @note if @note.persisted?
#   #   end
    
#   #   if @reminder.save
#   #     schedule_repeating_reminders(@reminder) if @reminder.repeat_interval.present? && @reminder.repeat_interval_unit.present?
#   #     render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }
#   #   else
#   #     render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
#   #   end
#   # end

#   # def update
#   #   if @reminder.update(reminder_params)
#   #     render json: convert_reminder_to_local_time(@reminder)
#   #   else
#   #     render json: { errors: @reminder.errors }, status: :unprocessable_entity
#   #   end
#   # end

#   def create
#     @reminder = current_user.reminders.new(reminder_params)
    
#     if note_params.present?
#       @note = current_user.notes.create(note_params)
#       @reminder.note = @note if @note.persisted?
#     end
    
#     if @reminder.save
#       schedule_reminder_notifications(@reminder)
#       render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }
#     else
#       render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
#     end
#   end

#   def destroy
#     @reminder.destroy
#     head :no_content
#   end

#   def index_by_date
#     date = Date.parse(params[:date])
#     start_date = date.beginning_of_day
#     end_date = date.end_of_day

#     reminders = current_user.reminders.where(due_date: start_date..end_date)

#     if reminders.present?
#       render json: reminders.map { |reminder| convert_reminder_to_local_time(reminder) }, status: :ok
#     else
#       render json: { error: 'No reminders found for the given date range' }, status: :not_found
#     end
#   rescue ArgumentError => e
#     render json: { error: e.message }, status: :bad_request
#   rescue StandardError => e
#     render json: { error: e.message }, status: :internal_server_error
#   end

#   private

#   def set_reminder
#     @reminder = current_user.reminders.find_by(id: params[:id])
#     unless @reminder
#       render json: { error: 'Reminder not found or unauthorized' }, status: :not_found
#     end
#   end

#   def reminder_params
#     params.require(:reminder).permit(:title, :description, :due_date, :user_id, :repeat_interval, :repeat_interval_unit, :note_id, :location, :priority, :calendar_id, :duration)
#   end

#   def note_params
#     params.require(:note).permit(:content) if params[:note].present?
#   end

#   def schedule_repeating_reminders(reminder)
#     case reminder.repeat_interval_unit
#     when 'daily', 'day'
#       create_daily_repeating_reminders(reminder)
#     when 'weekly'
#       create_weekly_repeating_reminders(reminder)
#     else
#       Rails.logger.error("Invalid repeat_interval_unit: #{reminder.repeat_interval_unit}")
#     end
#   end

#   def create_daily_repeating_reminders(reminder)
#     # Add logic to schedule daily repeating reminders
#   end

#   def create_weekly_repeating_reminders(reminder)
#     # Add logic to schedule weekly repeating reminders
#   end

#   def convert_to_utc(date_str)
#     Time.zone.parse(date_str).utc if date_str.present?
#   end

#   def convert_reminder_to_local_time(reminder)
#     reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S'))
#   end
#   def set_reminder
#     @reminder = current_user.reminders.find_by(id: params[:id])
#     unless @reminder
#       render json: { error: 'Reminder not found or unauthorized' }, status: :not_found
#     end
#   end

#   def reminder_params
#     params.require(:reminder).permit(:title, :description, :due_date, :user_id, :repeat_interval, :repeat_interval_unit, :note_id, :location, :priority, :calendar_id, :duration)
#   end

#   def note_params
#     params.require(:note).permit(:content) if params[:note].present?
#   end

#   def schedule_reminder_notifications(reminder)
#     # Schedule notifications for the reminder at specific intervals
#     SendReminderNotificationsWorker.perform_at(reminder.due_date - 24.hours, reminder.id, '24_hours')
#     SendReminderNotificationsWorker.perform_at(reminder.due_date - 30.minutes, reminder.id, '30_minutes')
#     SendReminderNotificationsWorker.perform_at(reminder.due_date - 15.minutes, reminder.id, '15_minutes')
#     SendReminderNotificationsWorker.perform_at(reminder.due_date - 5.minutes, reminder.id, '5_minutes')
#     SendReminderNotificationsWorker.perform_at(reminder.due_date, reminder.id, 'start')
#   end

#   def convert_reminder_to_local_time(reminder)
#     reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S'))
#   end
# end
# class RemindersController < ApplicationController
#   before_action :authenticate_user!
#   before_action :set_reminder, only: [:show, :update, :destroy]

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
    
#     if note_params.present?
#       @note = current_user.notes.create(note_params)
#       @reminder.note = @note if @note.persisted?
#     end
    
#     if @reminder.save
#       # Call the method to send notifications here
#       send_notifications(@reminder)
      
#       render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }, status: :created
#     else
#       render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
#     end
#   end

#   def destroy
#     @reminder.destroy
#     head :no_content
#   end

#   def index_by_date
#     date = Date.parse(params[:date])
#     start_date = date.beginning_of_day
#     end_date = date.end_of_day

#     reminders = current_user.reminders.where(due_date: start_date..end_date)

#     if reminders.present?
#       render json: reminders.map { |reminder| convert_reminder_to_local_time(reminder) }, status: :ok
#     else
#       render json: { error: 'No reminders found for the given date range' }, status: :not_found
#     end
#   rescue ArgumentError => e
#     render json: { error: e.message }, status: :bad_request
#   rescue StandardError => e
#     render json: { error: e.message }, status: :internal_server_error
#   end

#   private

#   def set_reminder
#     @reminder = current_user.reminders.find_by(id: params[:id])
#     unless @reminder
#       render json: { error: 'Reminder not found or unauthorized' }, status: :not_found
#     end
#   end

#   def reminder_params
#     params.require(:reminder).permit(:title, :description, :due_date, :user_id, :repeat_interval, :repeat_interval_unit, :note_id, :location, :priority, :calendar_id, :duration)
#   end

#   def note_params
#     params.require(:note).permit(:content) if params[:note].present?
#   end

#   def send_notifications(reminder)
#     # Calculate notification times based on the reminder's due date
#     due_date = reminder.due_date
#     notification_times = [
#       due_date - 24.hours,
#       due_date - 1.hour,
#       due_date - 30.minutes,
#       due_date - 5.minutes,
#       due_date
#     ]
  
#     # Send notifications for each time
#     notification_times.each do |time|
#       Notification.create(user_id: reminder.user_id, message: "Reminder: #{reminder.title}", created_at: time, updated_at: time)
#     end
#   end

#   def convert_to_utc(date_str)
#     Time.zone.parse(date_str).utc if date_str.present?
#   end

#   def convert_reminder_to_local_time(reminder)
#     reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S'))
#   end
# end

class RemindersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reminder, only: [:show, :update, :destroy]

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
    
    if note_params.present?
      @note = current_user.notes.create(note_params)
      @reminder.note = @note if @note.persisted?
    end
    
    if @reminder.save
      send_notifications(@reminder)
      logger.info "Reminder created: #{@reminder.inspect}"
      logger.info "Notifications created for reminder: #{Notification.where(reminder: @reminder).inspect}"
      render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }, status: :created
    else
      logger.error "Reminder creation failed: #{@reminder.errors.full_messages}"
      render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
    end
  end
 
  

  def destroy
    @reminder.destroy
    head :no_content
  end

  def complete
    @reminder = current_user.reminders.find_by(id: params[:id])
    unless @reminder
      render json: { error: 'Reminder not found or unauthorized' }, status: :not_found
      return
    end
  
    if @reminder.update(completed: true)
      # Create a new entry in the completed_tasks table
      CompletedTask.create(
        title: @reminder.title,
        description: @reminder.description,
        due_date: @reminder.due_date,
        user: current_user
      )
      render json: { status: 'success', message: 'Reminder completed successfully', reminder: convert_reminder_to_local_time(@reminder) }
    else
      render json: { status: 'error', message: 'Failed to complete reminder', errors: @reminder.errors }, status: :unprocessable_entity
    end
  end
  # def complete
  #   @reminder = current_user.reminders.find_by(id: params[:id])
  #   unless @reminder
  #     render json: { error: 'Reminder not found or unauthorized' }, status: :not_found
  #     return
  #   end
  
  #   if @reminder.update(completed: true)
  #     # Create a new entry in the completed_tasks table
  #     CompletedTask.create(
  #       title: @reminder.title,
  #       description: @reminder.description,
  #       due_date: @reminder.due_date,
  #       user: current_user
  #     )
  #     render json: { status: 'success', message: 'Reminder completed successfully', reminder: convert_reminder_to_local_time(@reminder) }
  #   else
  #     render json: { status: 'error', message: 'Failed to complete reminder', errors: @reminder.errors }, status: :unprocessable_entity
  #   end
  # end


  def index_by_date
    date = Date.parse(params[:date])
    start_date = date.beginning_of_day
    end_date = date.end_of_day

    reminders = current_user.reminders.where(due_date: start_date..end_date)

    if reminders.present?
      render json: reminders.map { |reminder| convert_reminder_to_local_time(reminder) }, status: :ok
    else
      render json: { error: 'No reminders found for the given date range' }, status: :not_found
    end
  rescue ArgumentError => e
    render json: { error: e.message }, status: :bad_request
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def set_reminder
    @reminder = current_user.reminders.find_by(id: params[:id])
    unless @reminder
      render json: { error: 'Reminder not found or unauthorized' }, status: :not_found
    end
  end

  def reminder_params
    params.require(:reminder).permit(:title, :description, :due_date, :user_id, :repeat_interval, :repeat_interval_unit, :note_id, :location, :priority, :calendar_id, :duration)
  end

  def note_params
    params.require(:note).permit(:content) if params[:note].present?
  end

  def send_notifications(reminder)
    due_date = reminder.due_date
    notification_times = [
      { time: due_date - 24.hours, schedule: "24_hours" },
      { time: due_date - 1.hour, schedule: "1_hour" },
      { time: due_date - 30.minutes, schedule: "30_minutes" },
      { time: due_date - 5.minutes, schedule: "5_minutes" },
      { time: due_date, schedule: "start" }
    ]
  
    notification_times.each do |nt|
      notification = Notification.create(
        user: reminder.user,
        reminder: reminder,
        message: "Reminder: #{reminder.title} - #{nt[:schedule]}",
        schedule: nt[:schedule],
        created_at: nt[:time]
      )
      if notification.persisted?
        logger.info "Notification created: #{notification.inspect}"
      else
        logger.error "Notification creation failed: #{notification.errors.full_messages}"
      end
    end
  end
  

  def convert_to_utc(date_str)
    Time.zone.parse(date_str).utc if date_str.present?
  end

  def convert_reminder_to_local_time(reminder)
    reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S'))
  end
end
