

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
#       send_notifications(@reminder)
#       logger.info "Reminder created: #{@reminder.inspect}"
#       logger.info "Notifications created for reminder: #{Notification.where(reminder: @reminder).inspect}"
#       render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }, status: :created
#     else
#       logger.error "Reminder creation failed: #{@reminder.errors.full_messages}"
#       render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
#     end
#   end
 
  

#   def destroy
#     @reminder.destroy
#     head :no_content
#   end

#   def complete
#     @reminder = current_user.reminders.find_by(id: params[:id])
#     unless @reminder
#       render json: { error: 'Reminder not found or unauthorized' }, status: :not_found
#       return
#     end
  
#     if @reminder.update(completed: true)
#       # Create a new entry in the completed_tasks table
#       CompletedTask.create(
#         title: @reminder.title,
#         description: @reminder.description,
#         due_date: @reminder.due_date,
#         user: current_user
#       )
#       render json: { status: 'success', message: 'Reminder completed successfully', reminder: convert_reminder_to_local_time(@reminder) }
#     else
#       render json: { status: 'error', message: 'Failed to complete reminder', errors: @reminder.errors }, status: :unprocessable_entity
#     end
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
#     notification_times = [
#       { time: reminder.due_date - 24.hours, schedule: "24_hours" },
#       { time: reminder.due_date - 1.hour, schedule: "1_hour" },
#       { time: reminder.due_date - 30.minutes, schedule: "30_minutes" },
#       { time: reminder.due_date - 5.minutes, schedule: "5_minutes" },
#       { time: reminder.due_date, schedule: "start" }
#     ]

#     notification_times.each do |nt|
#       notification = Notification.create(
#         user: reminder.user,
#         reminder: reminder,
#         message: "Reminder: #{reminder.title} - #{nt[:schedule]}",
#         schedule: nt[:schedule],
#         created_at: nt[:time]
#       )
#       logger.info "Notification created: #{notification.inspect}" if notification.persisted?
#       logger.error "Notification creation failed: #{notification.errors.full_messages}" unless notification.persisted?
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
      send_notifications(@reminder) if @reminder.due_date > Time.current
      logger.info "Reminder created: #{@reminder.inspect}"
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
    params.require(:reminder).permit(:title, :description, :due_date, :repeat_interval, :repeat_interval_unit, :location, :priority, :calendar_id, :duration)
  end

  def note_params
    params.require(:note).permit(:content) if params[:note].present?
  end

  # def send_notifications(reminder)
  #   notification_times = [
  #     { time: reminder.due_date - 24.hours, schedule: "24_hours" },
  #     { time: reminder.due_date - 1.hour, schedule: "1_hour" },
  #     { time: reminder.due_date - 30.minutes, schedule: "30_minutes" },
  #     { time: reminder.due_date - 5.minutes, schedule: "5_minutes" },
  #     { time: reminder.due_date, schedule: "start" }
  #   ]

  #   notification_times.each do |nt|
  #     if nt[:time] > Time.current
  #       notification = Notification.create(
  #         user: reminder.user,
  #         reminder: reminder,
  #         message: "Reminder: #{reminder.title} - #{nt[:schedule]}",
  #         schedule: nt[:schedule],
  #         created_at: nt[:time]
  #       )
  #       logger.info "Notification created: #{notification.inspect}" if notification.persisted?
  #       logger.error "Notification creation failed: #{notification.errors.full_messages}" unless notification.persisted?
  #     end
  #   end
  # end
  def send_notifications(reminder)
    notification_times = [
      { time: reminder.due_date - 24.hours, schedule: "24_hours" },
      { time: reminder.due_date - 1.hour, schedule: "1_hour" },
      { time: reminder.due_date - 30.minutes, schedule: "30_minutes" },
      { time: reminder.due_date - 5.minutes, schedule: "5_minutes" },
      { time: reminder.due_date, schedule: "start" }
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
      end
    end
  end
  

  def convert_reminder_to_local_time(reminder)
    reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S'))
  end
end
