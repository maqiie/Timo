class UserMailer < ApplicationMailer
  default from: 'noreply@remindapp.com'

  def otp_email(user, otp)
    @user = user
    @otp = otp
    mail(to: @user.email, subject: 'Your RemindApp verification code')
  end
end