class Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  def create
    super do |user|
      # After creating the user, check if it's the first user and make them an admin
      if User.count == 1
        user.update(role: 'admin')
      end
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
