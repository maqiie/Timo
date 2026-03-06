class Auth::SessionsController < DeviseTokenAuth::SessionsController
  respond_to :json

  def create
    @user = User.find_by(email: params[:email]&.downcase&.strip)

    unless @user&.valid_password?(params[:password])
      return render json: {
        status: 'error',
        message: 'Invalid email or password.'
      }, status: :unauthorized
    end

    otp = rand(100_000..999_999).to_s
    @user.update!(
      otp_code: BCrypt::Password.create(otp),
      otp_expires_at: 10.minutes.from_now
    )

    UserMailer.otp_email(@user, otp).deliver_now

    render json: {
      status: 'otp_required',
      message: 'Credentials verified. Check your email for the OTP.',
      email: @user.email
    }, status: :ok
  end

  def destroy
    cookies.delete(:user_id)
    super
  end
end