# class Notification < ApplicationRecord
#   belongs_to :user
#   belongs_to :reminder

#   validates :message, :schedule, :created_at, presence: true
# end
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :reminder

  scope :upcoming, -> { where('created_at >= ?', Time.current) }
  validates :message, :schedule, :created_at, presence: true

end
