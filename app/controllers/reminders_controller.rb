class RemindersController < ApplicationController
    # before_action :authenticate_user!
    def index
        if params[:query].present?
          @reminders = current_user.reminders.search(params[:query])
        else
          @reminders = current_user.reminders.order(:due_date)
        end
      end
      
    def show
      @reminder = current_user.reminders.find(params[:id])
    end
  
    def new
      @reminder = current_user.reminders.build
    end

    # def create
    #   @reminder = current_user.reminders.new(reminder_params)
  
    #   if @reminder.save
    #     if @reminder.repeat_interval.present? && @reminder.repeat_interval_unit.present?
    #       schedule_repeating_reminders(@reminder)
    #     end
    #   render json: { status: 'success', reminder: @reminder }
    #   else
    #     render :new
    #   end
    # end
    def create
      @reminder = current_user.reminders.new(reminder_params)
      
      if note_params.present? # Check if note parameters are present
        @note = current_user.notes.create(note_params)
        @reminder.note = @note if @note.persisted? # Associate the note with the reminder
      end
  
      if @reminder.save
        if @reminder.repeat_interval.present? && @reminder.repeat_interval_unit.present?
          schedule_repeating_reminders(@reminder)
        end
        render json: { status: 'success', reminder: @reminder }
      else
        render :new
      end
    end
  
  
   
 

    

  
    def note_params
      params.require(:note).permit(:content)
    end
  
    def schedule_repeating_reminders(reminder)
      case reminder.repeat_interval_unit
      when 'daily', 'day' # Add 'day' as a valid value
        create_daily_repeating_reminders(reminder)
      when 'weekly'
        create_weekly_repeating_reminders(reminder)
      # Add more cases for other repeat_interval_units (monthly, yearly, etc.)
      else
        # Default case if no valid repeat_interval_unit is provided
        Rails.logger.error("Invalid repeat_interval_unit: #{reminder.repeat_interval_unit}")
      end
    end
    
    private
    
    def create_daily_repeating_reminders(reminder)
      # Add logic to schedule daily repeating reminders
      # For example, you can create a background job to handle the scheduling
    end
    
    def create_weekly_repeating_reminders(reminder)
      # Add logic to schedule weekly repeating reminders
      # For example, you can create a background job to handle the scheduling
    end
    

  
    def edit
      @reminder = current_user.reminders.find(params[:id])
    end
  
    def update
      @reminder = current_user.reminders.find(params[:id])
      if @reminder.update(reminder_params)
        redirect_to @reminder, notice: 'Reminder was successfully updated.'
      else
        render :edit
      end
    end
  
    def destroy
      @reminder = current_user.reminders.find(params[:id])
      @reminder.destroy
      redirect_to reminders_url, notice: 'Reminder was successfully destroyed.'
    end
  
    # private
    # def reminder_params
    #   params.require(:reminder).permit(:title, :description, :due_date, :repeat_interval, :repeat_interval_unit,:attachment )
    # end
  
  
    # def reminder_params
    #   params.require(:reminder).permit(:title, :due_date, :description, :repeat_interval, :repeat_interval_unit, :attachment)
    # end
    private

   
    def reminder_params
      params.require(:reminder).permit(:title, :due_date, :description, :repeat_interval, :repeat_interval_unit, :attachment)
    end
  
  end
  