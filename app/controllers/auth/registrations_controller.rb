
class Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  
  # def create
  #   super do |user|
  #     if user.id == 1
  #       user.update(admin: true)
  #     end
  #   end
  # end

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
      params.permit(:name, :email, :password, :password_confirmation)
    end
  end
  
  