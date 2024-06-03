
# class Reminder < ApplicationRecord
#   belongs_to :user
#   belongs_to :note, optional: true
#   has_one :notification
#   has_one_attached :attachment
  
#   after_create :create_notification

#   validates :title, presence: true
#   validates :due_date, presence: true
#   validates :duration, presence: true
#   validates :repeat_interval_unit, inclusion: { in: %w(day week month) }, allow_blank: true
#   validates :repeat_interval, presence: true, allow_blank: true
#   validates :repeat_interval_unit, inclusion: { in: %w[day week month] }, allow_blank: true

#   validate :due_date_cannot_be_in_the_past

#   private

#   def create_notification
#     Notification.create(user: self.user, message: "Reminder: #{self.title}")
#   end
#   def schedule
#     # Logic to determine the schedule based on the due date
#     # For example, you might want to return different schedules based on the due date
#     # Here's a simple example where it returns 'start' if the due date is in the past, otherwise it returns 'future'
#     self.due_date.past? ? 'start' : 'future'
#   end

#   def self.search(query)
#     where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")
#   end

#   def due_date_cannot_be_in_the_past
#     errors.add(:due_date, "can't be in the past") if due_date.present? && due_date < Date.today
#   end
# end
class Reminder < ApplicationRecord
  belongs_to :user
  belongs_to :note, optional: true
  has_one :notification
  has_one_attached :attachment

  after_create :create_notification

  validates :title, presence: true
  validates :due_date, presence: true
  validates :duration, presence: true
  validates :repeat_interval_unit, inclusion: { in: %w(day week month) }, allow_blank: true
  validates :repeat_interval, presence: true, allow_blank: true

  validate :due_date_cannot_be_in_the_past

  def create_notification
    Notification.create(user: self.user, message: "Reminder: #{self.title}")
  end

  def schedule
    self.due_date.past? ? 'start' : 'future'
  end

  def self.search(query)
    where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")
  end

  def due_date_cannot_be_in_the_past
    errors.add(:due_date, "can't be in the past") if due_date.present? && due_date < Date.today
  end

  # Method to generate recurring reminders schedule
  def recurring_schedule
    schedule = IceCube::Schedule.new(due_date)
    case repeat_interval_unit
    when 'day'
      schedule.add_recurrence_rule IceCube::Rule.daily(repeat_interval)
    when 'week'
      schedule.add_recurrence_rule IceCube::Rule.weekly(repeat_interval)
    when 'month'
      schedule.add_recurrence_rule IceCube::Rule.monthly(repeat_interval)
    end
    schedule
  end
end
