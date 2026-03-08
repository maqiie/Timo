# app/models/conversation.rb
class Conversation < ApplicationRecord
  belongs_to :sender,    class_name: 'User', foreign_key: :sender_id
  belongs_to :recipient, class_name: 'User', foreign_key: :recipient_id

  has_many :messages, dependent: :destroy

  validates :sender_id,    presence: true
  validates :recipient_id, presence: true
  validate  :not_self_conversation
  validates :sender_id, uniqueness: { scope: :recipient_id, message: 'Conversation already exists' }

  scope :involving, ->(user) {
    where('sender_id = ? OR recipient_id = ?', user.id, user.id)
  }

  def self.between(user1_id, user2_id)
    where(
      '(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)',
      user1_id, user2_id, user2_id, user1_id
    ).first
  end

  def other_participant(current_user)
    sender_id == current_user.id ? recipient : sender
  end

  def unread_count(user)
    messages.where(read: false).where.not(user_id: user.id).count
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  private

  def not_self_conversation
    errors.add(:base, "Can't have a conversation with yourself") if sender_id == recipient_id
  end
end