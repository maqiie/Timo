# app/controllers/conversations_controller.rb
class ConversationsController < ApplicationController
  before_action :authenticate_user!

  # GET /conversations
  def index
    conversations = Conversation.involving(current_user)
                                .includes(:sender, :recipient, :messages)
                                .order(updated_at: :desc)

    render json: conversations.map { |c| serialize_conversation(c) }
  end

  # POST /conversations  { participant_id: 123 }
  def create
    other = User.find(params[:participant_id])

    conversation = Conversation.between(current_user.id, other.id) ||
                   Conversation.create!(
                     sender_id:    current_user.id,
                     recipient_id: other.id
                   )

    render json: serialize_conversation(conversation), status: :ok
  end

  # GET /conversations/:id/messages
  def messages
    conversation = find_authorized_conversation
    page     = (params[:page] || 1).to_i
    per_page = 30
    msgs = conversation.messages
                       .order(created_at: :desc)
                       .offset((page - 1) * per_page)
                       .limit(per_page)

    render json: { messages: msgs.map(&:as_json) }
  end

  # POST /conversations/:id/messages
  def create_message
    conversation = find_authorized_conversation
    message = conversation.messages.create!(
      user_id: current_user.id,
      content: params[:content].to_s.strip
    )
    # Mark other user's unread messages as read
    conversation.messages.where(read: false).where.not(user_id: current_user.id).update_all(read: true)
    render json: message.as_json, status: :created
  end

  # PATCH /conversations/:id/mark_read
  def mark_read
    conversation = find_authorized_conversation
    conversation.messages.where(read: false).where.not(user_id: current_user.id).update_all(read: true)
    render json: { ok: true }
  end

  private

  def find_authorized_conversation
    conv = Conversation.find(params[:id])
    unless conv.sender_id == current_user.id || conv.recipient_id == current_user.id
      render json: { error: 'Unauthorized' }, status: :forbidden and return
    end
    conv
  end

  def serialize_conversation(conv)
    other = conv.other_participant(current_user)
    last  = conv.last_message
    {
      id:                  conv.id,
      other_participant:   { id: other.id, name: other.name, email: other.email },
      last_message:        last ? { content: last.content, created_at: last.created_at, user_id: last.user_id } : nil,
      unread_count:        conv.unread_count(current_user),
      updated_at:          conv.updated_at,
    }
  end
end