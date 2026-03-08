# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Tokens come in as query params from the React Native WebSocket URL
      token  = request.params['access-token'] || request.headers['access-token']
      client = request.params['client']       || request.headers['client']
      uid    = request.params['uid']          || request.headers['uid']

      return reject_unauthorized_connection unless token && client && uid

      user = User.find_by(uid: uid)
      return reject_unauthorized_connection unless user

      # Validate token using devise_token_auth
      if user.valid_token?(token, client)
        user
      else
        reject_unauthorized_connection
      end
    end
  end
end
# module ApplicationCable
#   class Connection < ActionCable::Connection::Base
#     identified_by :current_user

#     def connect
#       self.current_user = find_verified_user
#     end

#     private

#     def find_verified_user
#       if verified_user = User.find_by(auth_token: request.params[:token])
#         verified_user
#       else
#         reject_unauthorized_connection
#       end
#     end
#   end
# end
