
class FriendRequestsController < ApplicationController
include Devise::Controllers::Helpers # Include Devise helpers
  before_action :authenticate_user!    # Ensure user is authenticated

  before_action :set_user

  
  # def accepted
  #   user_id = current_user.id
    
  #   # Fetch all bidirectional friendships where the current user is either user_id or friend_id
  #   friendships = Friendship.where("(user_id = :user_id OR friend_id = :user_id) AND status = 'accepted'", user_id: user_id)
    
  #   # Extract friend ids from friendships
  #   friend_ids = friendships.pluck(:user_id, :friend_id).flatten.uniq - [user_id]
    
  #   # Fetch details of accepted friends including their name and email
  #   @accepted_friends = User.where(id: friend_ids).select(:id, :name, :email)
    
  #   render json: @accepted_friends
  # end
  
  def accepted
    user_id = current_user.id
  
    # Fetch all bidirectional friendships where the current user is either user_id or friend_id
    friendships = Friendship.where("(user_id = :user_id OR friend_id = :user_id) AND status = 'accepted'", user_id: user_id)
  
    # Extract friend ids from friendships and include relationship category
    friend_ids_with_relationships = friendships.map do |friendship|
      {
        friend_id: friendship.user_id == user_id ? friendship.friend_id : friendship.user_id,
        relationship: friendship.relationship_category
      }
    end
  
    # Fetch details of accepted friends including their name, email, and relationship category
    @accepted_friends = friend_ids_with_relationships.map do |friend_info|
      user = User.select(:id, :name, :email).find(friend_info[:friend_id])
      {
        id: user.id,
        name: user.name,
        email: user.email,
        relationship: friend_info[:relationship]
      }
    end
  
    render json: @accepted_friends
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

  

  # def accept
  #   @friend_request = FriendRequest.find(params[:id])
  #   if @friend_request.update(status: 'accepted')
  #     FriendRequestMailer.request_accepted_email(@friend_request).deliver_now
  #     render json: @friend_request, status: :ok
  #   else
  #     render json: { error: 'Failed to accept friend request' }, status: :unprocessable_entity
  #   end
  # end
  # def accept
  #   @friend_request = FriendRequest.find(params[:id])
  
  #   if @friend_request.update(status: 'accepted')
  #     sender = User.find(@friend_request.sender_id)
  #     receiver = User.find(@friend_request.receiver_id)
  
  #     # Create bidirectional friendships
  #     Friendship.create(user_id: sender.id, friend_id: receiver.id, status: 'accepted')
  #     Friendship.create(user_id: receiver.id, friend_id: sender.id, status: 'accepted')
  
  #     FriendRequestMailer.request_accepted_email(@friend_request).deliver_now
  #     render json: @friend_request, status: :ok
  #   else
  #     render json: { error: 'Failed to accept friend request' }, status: :unprocessable_entity
  #   end
  # end
  def accept
    friend_request = FriendRequest.find(params[:id])
  
    if friend_request.update(status: 'accepted')
      # Find or create the friendship and update the relationship_category
      friendship = Friendship.find_or_create_by(
        user_id: friend_request.sender_id,
        friend_id: friend_request.receiver_id
      )
      friendship.update(relationship_category: friend_request.relationship_category, status: 'accepted')
  
      render json: { message: "Friend request accepted successfully." }, status: :ok
    else
      render json: { error: "Unable to accept friend request." }, status: :unprocessable_entity
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

  def set_user
    @user = current_user
    unless @user
      render json: { error: "Please log in" }, status: :unauthorized
    end
  end
end
