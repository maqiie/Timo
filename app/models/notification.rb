class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :reminder

  validates :message, :schedule, :created_at, presence: true
end
