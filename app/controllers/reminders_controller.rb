
# class RemindersController < ApplicationController
#   before_action :authenticate_user!
#   before_action :set_reminder, only: [:show, :update, :destroy]

#   def index
#     @reminders = Reminder.all
#     render json: @reminders
#   end

 
#   def show
#     @reminder = Reminder.find(params[:id])
#     render json: @reminder
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Reminder not found' }, status: :not_found
#   end
  

#   def create
#         @reminder = current_user.reminders.new(reminder_params)
      
#         if note_params.present?
#           @note = current_user.notes.create(note_params)
#           @reminder.note = @note if @note.persisted?
#         end
      
#         if @reminder.save
#           schedule_repeating_reminders(@reminder) if @reminder.repeat_interval.present? && @reminder.repeat_interval_unit.present?
#           render json: { status: 'success', message: 'Reminder created successfully', reminder: @reminder }
#         else
#           render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
#         end
#       end

  

#   def update
#     if @reminder.update(reminder_params)
#       render json: @reminder
#     else
#       render json: { errors: @reminder.errors }, status: :unprocessable_entity
#     end
#   end

#   def destroy
#     @reminder.destroy
#     head :no_content
#   end
#   def index_by_date
#     # Parse the date parameter to get the start and end of the day
#     date = Date.parse(params[:date])
#     start_date = date.beginning_of_day
#     end_date = date.end_of_day
  
#     # Query reminders within the specified date range
#     reminders = Reminder.where(due_date: start_date..end_date)
  
#     if reminders.present?
#       render json: reminders, status: :ok
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
#     params.require(:reminder).permit(:title, :due_date, :priority, :location, :description)
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
# end
# class RemindersController < ApplicationController
#   before_action :authenticate_user!
#   before_action :set_reminder, only: [:show, :update, :destroy]

#   def index
#     @reminders = current_user.reminders
#     render json: @reminders
#   end

#   def show
#     render json: @reminder
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
#       schedule_repeating_reminders(@reminder) if @reminder.repeat_interval.present? && @reminder.repeat_interval_unit.present?
#       render json: { status: 'success', message: 'Reminder created successfully', reminder: @reminder }
#     else
#       render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
#     end
#   end
 

#   def update
#     if @reminder.update(reminder_params)
#       render json: @reminder
#     else
#       render json: { errors: @reminder.errors }, status: :unprocessable_entity
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
#       render json: reminders, status: :ok
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
      schedule_repeating_reminders(@reminder) if @reminder.repeat_interval.present? && @reminder.repeat_interval_unit.present?
      render json: { status: 'success', message: 'Reminder created successfully', reminder: convert_reminder_to_local_time(@reminder) }
    else
      render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @reminder.update(reminder_params)
      render json: convert_reminder_to_local_time(@reminder)
    else
      render json: { errors: @reminder.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @reminder.destroy
    head :no_content
  end

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

  def schedule_repeating_reminders(reminder)
    case reminder.repeat_interval_unit
    when 'daily', 'day'
      create_daily_repeating_reminders(reminder)
    when 'weekly'
      create_weekly_repeating_reminders(reminder)
    else
      Rails.logger.error("Invalid repeat_interval_unit: #{reminder.repeat_interval_unit}")
    end
  end

  def create_daily_repeating_reminders(reminder)
    # Add logic to schedule daily repeating reminders
  end

  def create_weekly_repeating_reminders(reminder)
    # Add logic to schedule weekly repeating reminders
  end

  def convert_to_utc(date_str)
    Time.zone.parse(date_str).utc if date_str.present?
  end

  def convert_reminder_to_local_time(reminder)
    reminder.attributes.merge('due_date' => reminder.due_date.in_time_zone('Africa/Nairobi').strftime('%Y-%m-%d %H:%M:%S'))
  end
  
end
