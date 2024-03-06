class RemindersController < ApplicationController
    before_action :authenticate_user!
  
    def index
        @reminders = current_user.reminders.order(:due_date)
      end
      
    def show
      @reminder = current_user.reminders.find(params[:id])
    end
  
    def new
      @reminder = current_user.reminders.build
    end
  
    def create
      @reminder = current_user.reminders.build(reminder_params)
      if @reminder.save
        redirect_to @reminder, notice: 'Reminder was successfully created.'
      else
        render :new
      end
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
  
    private
  
    def reminder_params
      params.require(:reminder).permit(:title, :description, :due_date)
    end
  end
  