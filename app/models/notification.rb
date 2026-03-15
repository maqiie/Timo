class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :reminder, optional: true

  scope :upcoming, -> { where('schedule >= ?', Time.current) }

  validates :message,  presence: true
  validates :schedule, presence: true
  # ✅ created_at is set automatically by Rails — never validate it manually
end