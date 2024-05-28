class SendNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    notification = Notification.find(notification_id)
    # Logic to send notification
    NotificationService.send_notification(notification)
    # Optional: Mark notification as sent
    notification.update(sent: true)
  end

  
end
