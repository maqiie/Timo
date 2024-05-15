class RemindersController < ApplicationController
  before_action :authenticate_user!
  # before_action :set_reminder, only: [ :create, :show, :edit, :update, :destroy]
  def index
    @reminders = Reminder.all
    render json: @reminders
  end
  def show
  end

  def new
    @reminder = current_user.reminders.build
  end

  

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
  
  def edit
  end

  def update
    if @reminder.update(reminder_params)
      redirect_to @reminder, notice: 'Reminder was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @reminder.destroy
    redirect_to reminders_url, notice: 'Reminder was successfully destroyed.'
  end

  private

  def set_reminder
    @reminder = current_user.reminders.find(params[:id])
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
    # Add more cases for other repeat_interval_units (monthly, yearly, etc.)
    else
      Rails.logger.error("Invalid repeat_interval_unit: #{reminder.repeat_interval_unit}")
    end
  end

  def create_daily_repeating_reminders(reminder)
    # Add logic to schedule daily repeating reminders
    # For example, you can create a background job to handle the scheduling
  end

  def create_weekly_repeating_reminders(reminder)
    # Add logic to schedule weekly repeating reminders
    # For example, you can create a background job to handle the scheduling
  end
end
