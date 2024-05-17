# class RemindersController < ApplicationController
#   before_action :authenticate_user!
#   # before_action :set_reminder, only: [ :create, :show, :edit, :update, :destroy]
#   def index
#     @reminders = Reminder.all
#     render json: @reminders
#   end
#   def show
#     @task = Task.find(params[:id])
#     render json: @task
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Task not found' }, status: :not_found
#   end

#   def new
#     @reminder = current_user.reminders.build
#   end
#   def index_by_date
#     date = params[:date]
#     tasks = Task.where(due_date: date) # Adjust the query based on your schema
    
#     if tasks.present?
#       render json: tasks, status: :ok
#     else
#       render json: { error: 'No tasks found for the given date' }, status: :not_found
#     end
#   rescue StandardError => e
#     render json: { error: e.message }, status: :internal_server_error
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
  
#   def edit
#   end

#   def update
#     if @reminder.update(reminder_params)
#       redirect_to @reminder, notice: 'Reminder was successfully updated.'
#     else
#       render :edit
#     end
#   end

#   def destroy
#     @reminder.destroy
#     redirect_to reminders_url, notice: 'Reminder was successfully destroyed.'
#   end

#   private

#   def set_reminder
#     @reminder = current_user.reminders.find(params[:id])
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
#     # Add more cases for other repeat_interval_units (monthly, yearly, etc.)
#     else
#       Rails.logger.error("Invalid repeat_interval_unit: #{reminder.repeat_interval_unit}")
#     end
#   end

#   def create_daily_repeating_reminders(reminder)
#     # Add logic to schedule daily repeating reminders
#     # For example, you can create a background job to handle the scheduling
#   end

#   def create_weekly_repeating_reminders(reminder)
#     # Add logic to schedule weekly repeating reminders
#     # For example, you can create a background job to handle the scheduling
#   end
# end
# config/routes.rb
# app/controllers/reminders_controller.rb
class RemindersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reminder, only: [:show, :update, :destroy]

  def index
    @reminders = Reminder.all
    render json: @reminders
  end

 
  def show
    @reminder = Reminder.find(params[:id])
    render json: @reminder
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Reminder not found' }, status: :not_found
  end
  

  # def create
  #   @reminder = current_user.reminders.new(reminder_params)
  
  #   if note_params.present?
  #     @note = current_user.notes.create(note_params)
  #     @reminder.note = @note if @note.persisted?
  #   end
  
  #   if @reminder.save
  #     schedule_repeating_reminders(@reminder) if @reminder.repeat_interval.present? && @reminder.repeat_interval_unit.present?
  #     render json: { status: 'success', message: 'Reminder created successfully', reminder: @reminder }
  #   else
  #     render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
  #   end
  # end
  def create
        @reminder = current_user.reminders.new(reminder_params)
      
        if note_params.present?
          @note = current_user.notes.create(note_params)
          @reminder.note = @note if @note.persisted?
        end
      
        if @reminder.save
          schedule_repeating_reminders(@reminder) if @reminder.repeat_interval.present? && @reminder.repeat_interval_unit.present?
          render json: { status: 'success', message: 'Reminder created successfully', reminder: @reminder }
        else
          render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
        end
      end
  # def create
  #   @reminder = current_user.reminders.new(reminder_params)
  
  #   # Create a note associated with the reminder if note parameters are present
  #   if note_params.present?
  #     @note = current_user.notes.create(note_params)
  #     @reminder.note = @note if @note.persisted?
  #   end
  #   Rails.logger.debug @reminder.errors.full_messages

  #   if @reminder.save
  #     # If the reminder is successfully saved, schedule repeating reminders if applicable
  #     schedule_repeating_reminders(@reminder) if @reminder.repeat_interval.present? && @reminder.repeat_interval_unit.present?
  #     render json: { status: 'success', message: 'Reminder created successfully', reminder: @reminder }
  #   else
  #     # If there are validation errors, return an error response with error messages
  #     render json: { status: 'error', message: 'Failed to create reminder', errors: @reminder.errors }, status: :unprocessable_entity
  #   end
  # end
  

  def update
    if @reminder.update(reminder_params)
      render json: @reminder
    else
      render json: { errors: @reminder.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @reminder.destroy
    head :no_content
  end
  def index_by_date
    # Parse the date parameter to get the start and end of the day
    date = Date.parse(params[:date])
    start_date = date.beginning_of_day
    end_date = date.end_of_day
  
    # Query reminders within the specified date range
    reminders = Reminder.where(due_date: start_date..end_date)
  
    if reminders.present?
      render json: reminders, status: :ok
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
    params.require(:reminder).permit(:title, :due_date, :priority, :location, :description)
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
end
