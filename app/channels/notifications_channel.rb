# # app/channels/notifications_channel.rb
# class NotificationsChannel < ApplicationCable::Channel
#   def subscribed
#     if current_user
#       stream_from "notifications_#{current_user.id}"
#     else
#       reject
#     end
#   end

#   def unsubscribed
#     stop_all_streams
#   end

#   private

#   def current_user
#     @current_user ||= find_verified_user
#   end

#   def find_verified_user
#     # Implement your logic to find and verify the user
#     # For example, using Devise:
#     if verified_user = env['warden'].user
#       verified_user
#     else
#       reject_unauthorized_connection
#     end
#   end
# end
# class NotificationsChannel < ApplicationCable::Channel
#   def subscribed
#     stream_from "notifications:#{current_user.id}"
#   end

#   def unsubscribed
#     # Any cleanup needed when channel is unsubscribed
#   end
# end
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications_#{params[:user_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
