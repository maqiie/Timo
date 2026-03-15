# app/channels/chat_channel.rb
# Named ChatChannel to match the frontend subscription
class ChatChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find_by(id: params[:conversation_id])
    if conversation && authorized?(conversation)
      stream_for conversation
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  def send_message(data)
    conversation = Conversation.find_by(id: params[:conversation_id])
    return unless conversation && authorized?(conversation)

    content = data['content'].to_s.strip
    return if content.blank?

    conversation.messages.create!(
      user_id: current_user.id,
      content: content
    )

    conversation.messages
                .where(read: false)
                .where.not(user_id: current_user.id)
                .update_all(read: true)
  end

  def typing(data)
    conversation = Conversation.find_by(id: params[:conversation_id])
    return unless conversation && authorized?(conversation)

    broadcast_to(conversation, {
      type:    'typing',
      user_id: current_user.id,
    })
  end

  private

  def authorized?(conversation)
    conversation.sender_id    == current_user.id ||
      conversation.recipient_id == current_user.id
  end
end