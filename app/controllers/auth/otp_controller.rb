class Auth::OtpController < ApplicationController
  before_action :set_user_by_email

  # POST /auth/send_otp
  def send_otp
    return render json: { error: 'User not found' }, status: :not_found unless @user

    otp = rand(100_000..999_999).to_s
    @user.update!(
      otp_code: BCrypt::Password.create(otp),
      otp_expires_at: 10.minutes.from_now
    )

UserMailer.otp_email(@user, otp).deliver_now
    render json: { message: 'OTP sent successfully', expires_in: 600 }
  end

  # POST /auth/verify_otp
  def verify_otp
    return render json: { error: 'User not found' }, status: :not_found unless @user
    return render json: { error: 'OTP expired. Request a new one.' }, status: :unprocessable_entity if @user.otp_expires_at.nil? || @user.otp_expires_at < Time.current

    unless BCrypt::Password.new(@user.otp_code) == params[:otp].to_s
      return render json: { error: 'Invalid OTP code.' }, status: :unprocessable_entity
    end

    # Clear OTP after successful verification
    @user.update!(otp_code: nil, otp_expires_at: nil)

    # Generate fresh auth tokens
    tokens = @user.create_new_auth_token

    render json: {
      status: 'success',
      message: 'OTP verified successfully',
      data: @user.as_json,
      tokens: tokens
    }, headers: tokens, status: :ok
  end

  # POST /auth/resend_otp
  def resend_otp
    send_otp
  end

  private

  def set_user_by_email
    @user = User.find_by(email: params[:email]&.downcase&.strip)
  end
end