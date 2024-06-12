# class FriendRequestsController < ApplicationController
#   before_action :authenticate_user!


  
#   def accepted
#     # Fetch accepted friend requests for the current user
#     user_id = current_user.id # Assuming you have a method to get the current user
#     @accepted_requests = FriendRequest.where(receiver_id: user_id, status: 'accepted').includes(:sender)
  
#     render json: @accepted_requests, include: { sender: { only: [:id, :name, :email] } }
#   end
  
  
#   # def create
#   #   @friend_request = current_user.sent_friend_requests.build(
#   #     receiver_id: params[:receiver_id],
#   #     relationship_category: params[:relationship_category]
#   #   )
#   #   if @friend_request.save
#   #     render json: @friend_request, status: :created
#   #   else
#   #     render json: @friend_request.errors, status: :unprocessable_entity
#   #   end
#   # end
#   def create
#     @friend_request = current_user.sent_friend_requests.build(
#       receiver_id: params[:receiver_id],
#       relationship_category: params[:relationship_category]
#     )
  
#     if @friend_request.save
#       # Send email notification to the receiver
#       FriendRequestMailer.with(
#         sender: current_user,
#         receiver: @friend_request.receiver,
#         email_type: 'received'
#       ).request_received_email.deliver_later
  
#       render json: @friend_request, status: :created
#     else
#       render json: @friend_request.errors, status: :unprocessable_entity
#     end
#   end
  
  
#   def sent
#     @sent_requests = current_user.sent_friend_requests.includes(:receiver)
#     render json: @sent_requests.as_json(include: { receiver: { only: [:id, :email, :name] } })
#   end

#   def received
#     @received_requests = current_user.received_friend_requests.includes(:sender)
#     render json: @received_requests.as_json(include: { sender: { only: [:id, :email, :name] } })
#   end
#   # def accept
#   #   @friend_request = FriendRequest.find(params[:id])

#   #   if @friend_request.update(status: 'accepted')
#   #     render json: { message: 'Friend request accepted successfully' }, status: :ok
#   #   else
#   #     render json: { error: 'Failed to accept friend request' }, status: :unprocessable_entity
#   #   end
#   # end
#    # PATCH /friend_requests/:id/accept
#    def accept
#     @friend_request = FriendRequest.find(params[:id])
  
#     if @friend_request.update(status: 'accepted')
#       # Send email notification to the sender
#       FriendRequestMailer.with(
#         sender: @friend_request.receiver,
#         receiver: @friend_request.sender,
#         email_type: 'accepted'
#       ).request_accepted_email.deliver_later
  
#       render json: { message: 'Friend request accepted successfully' }, status: :ok
#     else
#       render json: { error: 'Failed to accept friend request' }, status: :unprocessable_entity
#     end
#   end
  


#   # def decline
#   #   @friend_request = FriendRequest.find(params[:id])

#   #   if @friend_request.update(status: 'declined')
#   #     render json: { message: 'Friend request declined successfully' }, status: :ok
#   #   else
#   #     render json: { error: 'Failed to decline friend request' }, status: :unprocessable_entity
#   #   end
#   # end
#   # PATCH /friend_requests/:id/decline
#   def decline
#     @friend_request = FriendRequest.find(params[:id])
  
#     if @friend_request.update(status: 'declined')
#       # Send email notification to the sender
#       FriendRequestMailer.with(
#         sender: @friend_request.receiver,
#         receiver: @friend_request.sender,
#         email_type: 'declined'
#       ).request_declined_email.deliver_later
  
#       render json: { message: 'Friend request declined successfully' }, status: :ok
#     else
#       render json: { error: 'Failed to decline friend request' }, status: :unprocessable_entity
#     end
#   end
  
# end
class FriendRequestsController < ApplicationController
  before_action :authenticate_user!

  def accepted
    user_id = current_user.id
    @accepted_requests = FriendRequest.where(receiver_id: user_id, status: 'accepted').includes(:sender)
    render json: @accepted_requests, include: { sender: { only: [:id, :name, :email] } }
  end

  def create
    @friend_request = FriendRequest.new(sender_id: current_user.id, receiver_id: params[:receiver_id], relationship_category: params[:relationship_category])
    
    if @friend_request.save
      begin
        FriendRequestMailer.request_received_email(@friend_request).deliver_now
        render json: @friend_request, status: :created
      rescue StandardError => e
        @friend_request.destroy
        Rails.logger.error "Failed to send email: #{e.message}"
        render json: { error: 'Failed to send email' }, status: :unprocessable_entity
      end
    else
      render json: @friend_request.errors, status: :unprocessable_entity
    end
  end

  def sent
    @sent_requests = current_user.sent_friend_requests.includes(:receiver)
    render json: @sent_requests.as_json(include: { receiver: { only: [:id, :email, :name] } })
  end

  def received
    @received_requests = current_user.received_friend_requests.includes(:sender)
    render json: @received_requests.as_json(include: { sender: { only: [:id, :email, :name] } })
  end

  

  def accept
    @friend_request = FriendRequest.find(params[:id])
    if @friend_request.update(status: 'accepted')
      FriendRequestMailer.request_accepted_email(@friend_request).deliver_now
      render json: @friend_request, status: :ok
    else
      render json: { error: 'Failed to accept friend request' }, status: :unprocessable_entity
    end
  end

  def decline
    @friend_request = FriendRequest.find(params[:id])
    if @friend_request.update(status: 'declined')
      FriendRequestMailer.request_declined_email(@friend_request).deliver_now
      render json: @friend_request, status: :ok
    else
      render json: { error: 'Failed to decline friend request' }, status: :unprocessable_entity
    end
  end
end
