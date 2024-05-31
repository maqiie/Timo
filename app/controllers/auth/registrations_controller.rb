# class Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
#   def create
#     super do |user|
#       # After creating the user, check if it's the first user and make them an admin
#       if User.count == 1
#         user.update(role: 'admin')
#       else
#         user.update(role: 'user')
        
#       end
#       end
#     end
#   end

#   private

#   def sign_up_params
#     params.require(:user).permit(:name, :email, :password, :password_confirmation,:nickname)
#   end
# end
class Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
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
end
