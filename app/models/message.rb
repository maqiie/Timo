# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates :content, presence: true
  validates :user_id, presence: true

  after_create_commit :broadcast_message

  def as_json(options = {})
    super(options.merge(only: [:id, :content, :user_id, :read, :created_at, :updated_at]))
  end

  private

  def broadcast_message
    ChatChannel.broadcast_to(
      conversation,
      {
        type:    'message',
        message: as_json
      }
    )
  end
end