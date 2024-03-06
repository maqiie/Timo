# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController
    def index
      @notifications = current_user.notifications.order(created_at: :desc)
    end
  
    def create
      message = params[:message]
      reminder_time = params[:reminder_time].to_time
  
      # Create the initial notification
      NotificationService.notify(current_user, message)
  
      # Schedule recurring notifications if the reminder time is within an hour
      NotificationService.schedule_recurring_notification(current_user, message, reminder_time)
  
      redirect_to notifications_path, notice: 'Notification sent successfully.'
    end
  end
  