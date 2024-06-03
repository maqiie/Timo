
# class Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
#   def create
#     super do |user|
#       # After creating the user, check if it's the first user and make them an admin
#       user.update(role: User.first.nil? ? 'admin' : 'user')
#     end
#   end

#   private

#   def sign_up_params
#     params.require(:user).permit(:name, :email, :password, :password_confirmation, :nickname)
#   end
# end
class Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  before_action :configure_permitted_parameters, if: :devise_controller?

  def create
    super do |user|
      # After creating the user, check if it's the first user and make them an admin
      user.update(role: User.first.nil? ? 'admin' : 'user')
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :nickname)
  end

  def account_update_params
    params.require(:user).permit(:name, :email, :nickname, :birthday, :role, :uid, :image)
  end
  

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation, :nickname])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :nickname, :birthday, :role, :uid])
  end
end
