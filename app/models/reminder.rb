class Reminder < ApplicationRecord
  belongs_to :user
  belongs_to :note, optional: true
  has_one :notification
  has_one_attached :attachment
  
  after_create :create_notification
  validates :repeat_interval_unit, inclusion: { in: %w(day week month) }
  validates :title, presence: true
  validates :due_date, presence: true
  validates :repeat_interval, presence: true
  validates :repeat_interval_unit, presence: true, inclusion: { in: %w[day week month] }

  validate :due_date_cannot_be_in_the_past

  private

  def create_notification
    Notification.create(user: self.user, message: "Reminder: #{self.title}")
  end

  def self.search(query)
    where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")
  end

  def due_date_cannot_be_in_the_past
    errors.add(:due_date, "can't be in the past") if due_date.present? && due_date < Date.today
  end
end
