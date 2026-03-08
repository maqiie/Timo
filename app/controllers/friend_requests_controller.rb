# app/controllers/friend_requests_controller.rb
class FriendRequestsController < ApplicationController
  include Devise::Controllers::Helpers
  before_action :authenticate_user!
  before_action :set_friend_request, only: [:accept, :decline]

  def accepted
    user_id = current_user.id

    friendships = Friendship.where(
      "(user_id = :user_id OR friend_id = :user_id) AND status = 'accepted'",
      user_id: user_id
    )

    @accepted_friends = friendships.filter_map do |friendship|
      # Get the OTHER person's id, not current user's
      other_id = friendship.user_id == user_id ? friendship.friend_id : friendship.user_id
      next if other_id == user_id # safety check — skip if same user

      user = User.select(:id, :name, :email).find_by(id: other_id)
      next unless user

      {
        id:           user.id,
        name:         user.name,
        email:        user.email,
        relationship: friendship.relationship_category
      }
    end

    render json: @accepted_friends
  end

  # POST /friend_requests
  def create
    @friend_request = FriendRequest.new(friend_request_params.merge(sender_id: current_user.id))

    if @friend_request.save
      # Email — fire and forget, never kill the saved record
      begin
        FriendRequestMailer.request_received_email(@friend_request).deliver_later
      rescue StandardError => e
        Rails.logger.error "Failed to queue email: #{e.message}"
      end

      # Broadcast — isolated, Redis being down won't affect the response
      begin
        broadcast_notification(
          @friend_request.receiver_id,
          "#{current_user.name} sent you a friend request.",
          @friend_request.id
        )
      rescue StandardError => e
        Rails.logger.error "Failed to broadcast: #{e.message}"
      end

      render json: @friend_request, status: :created
    else
      render json: @friend_request.errors, status: :unprocessable_entity
    end
  end

  # GET /friend_requests/:id/sent
  def sent
    @sent_requests = current_user.sent_friend_requests.includes(:receiver)
    render json: @sent_requests.as_json(include: { receiver: { only: [:id, :email, :name] } })
  end

  # GET /friend_requests/:id/received
  def received
    @received_requests = current_user.received_friend_requests.includes(:sender)
    render json: @received_requests.as_json(include: { sender: { only: [:id, :email, :name] } })
  end

  # PUT /friend_requests/:id/accept
  def accept
    if @friend_request.update(status: 'accepted')
      friendship = Friendship.find_or_create_by(
        user_id:   @friend_request.sender_id,
        friend_id: @friend_request.receiver_id
      ) do |f|
        # Default to 'friend' if no relationship category was specified
        f.relationship_category = @friend_request.relationship_category.presence || 'friend'
        f.status = 'accepted'
      end

      # Update existing record too in case it already existed
      friendship.update(
        relationship_category: friendship.relationship_category.presence || @friend_request.relationship_category.presence || 'friend',
        status: 'accepted'
      )

      begin
        broadcast_notification(
          @friend_request.sender_id,
          "#{current_user.name} accepted your friend request.",
          @friend_request.id
        )
      rescue StandardError => e
        Rails.logger.error "Failed to broadcast accept: #{e.message}"
      end

      render json: { message: "Friend request accepted successfully." }, status: :ok
    else
      render json: { error: "Unable to accept friend request." }, status: :unprocessable_entity
    end
  end

  # PUT /friend_requests/:id/decline
  def decline
    if @friend_request.update(status: 'declined')
      begin
        FriendRequestMailer.request_declined_email(@friend_request).deliver_later
      rescue StandardError => e
        Rails.logger.error "Failed to queue decline email: #{e.message}"
      end

      begin
        broadcast_notification(
          @friend_request.sender_id,
          "#{current_user.name} declined your friend request.",
          @friend_request.id
        )
      rescue StandardError => e
        Rails.logger.error "Failed to broadcast decline: #{e.message}"
      end

      render json: @friend_request, status: :ok
    else
      render json: { error: 'Failed to decline friend request' }, status: :unprocessable_entity
    end
  end

  private

  def set_friend_request
    @friend_request = FriendRequest.find(params[:id])
  end

  def friend_request_params
    params.permit(:receiver_id, :relationship_category)
  end

  def broadcast_notification(user_id, message, friend_request_id)
    NotificationsChannel.broadcast_to(
      "notifications_#{user_id}",
      message:           message,
      friend_request_id: friend_request_id
    )
  end
end