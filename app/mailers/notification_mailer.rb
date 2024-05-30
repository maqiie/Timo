# app/mailers/notification_mailer.rb
class NotificationMailer < ApplicationMailer
  def notification_email(recipient, subject, message)
    @message = message.presence || "No message provided"
    mail(to: recipient, subject: subject.presence || "No Subject")
  end
end
