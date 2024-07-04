# class Reminder < ApplicationRecord
#   belongs_to :user, optional: true  # Remove optional: true if user_id is required

#   has_many :reminder_users, dependent: :destroy
#   has_many :users, through: :reminder_users
#   has_one :notification
#   has_one_attached :attachment
#   has_many :invitations
#   has_many :invited_users, through: :invitations, source: :user
#   has_many :tagged_users, through: :reminder_users, source: :user

#   after_create :create_notification
  
#   validates :user_id, presence: true, unless: -> { user.nil? }
#   validates :title, presence: true
#   validates :due_date, presence: true
#   validates :duration, presence: true
#   validates :repeat_interval_unit, inclusion: { in: %w(day week month) }, allow_blank: true
#   validates :repeat_interval, presence: true, allow_blank: true
#   validates :duration, presence: true # Change to allow_nil: true or remove this line if duration is optional

#   validate :due_date_cannot_be_in_the_past

#   def add_user(user, relationship_category)
#     reminder_users.create(user: user, relationship_category: relationship_category)
#   end
  
#   def create_notification
#     Notification.create(user: self.user, message: "Reminder: #{self.title}")
#   end

#   def schedule
#     self.due_date.past? ? 'start' : 'future'
#   end

#   def self.search(query)
#     where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")
#   end

#   def due_date_cannot_be_in_the_past
#     errors.add(:due_date, "can't be in the past") if due_date.present? && due_date < Date.today
#   end

#   # Method to generate recurring reminders schedule
#   def recurring_schedule
#     schedule = IceCube::Schedule.new(due_date)
#     case repeat_interval_unit
#     when 'day'
#       schedule.add_recurrence_rule IceCube::Rule.daily(repeat_interval)
#     when 'week'
#       schedule.add_recurrence_rule IceCube::Rule.weekly(repeat_interval)
#     when 'month'
#       schedule.add_recurrence_rule IceCube::Rule.monthly(repeat_interval)
#     end
#     schedule
#   end
  
#   scope :special_events, -> { where(is_special_event: true) }

#   # Remove attr_accessible
# end
# class Reminder < ApplicationRecord
#   belongs_to :user
#   has_many :reminder_users, dependent: :destroy
#   has_many :users, through: :reminder_users
#   has_one :notification
#   has_one_attached :attachment
#   has_many :invitations
#   has_many :invited_users, through: :invitations, source: :user
#   has_many :tagged_users, through: :reminder_users, source: :user

#   after_create :create_notification

#   validates :user_id, presence: true, unless: -> { user.nil? }
#   validates :title, :due_date, :duration, presence: true
#   validates :repeat_interval_unit, inclusion: { in: %w(day week month) }, allow_blank: true
#   validates :repeat_interval, presence: true, allow_blank: true
#   validate :due_date_cannot_be_in_the_past

#   def add_user(user, relationship_category)
#     reminder_users.create(user: user, relationship_category: relationship_category)
#   end

#   def create_notification
#     Notification.create(user: self.user, message: "Reminder: #{self.title}")
#   end

#   def schedule
#     self.due_date.past? ? 'start' : 'future'
#   end

#   def self.search(query)
#     where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")
#   end

#   def due_date_cannot_be_in_the_past
#     errors.add(:due_date, "can't be in the past") if due_date.present? && due_date < Date.today
#   end

#   # Method to generate recurring reminders schedule
#   def recurring_schedule
#     schedule = IceCube::Schedule.new(due_date)
#     case repeat_interval_unit
#     when 'day'
#       schedule.add_recurrence_rule IceCube::Rule.daily(repeat_interval)
#     when 'week'
#       schedule.add_recurrence_rule IceCube::Rule.weekly(repeat_interval)
#     when 'month'
#       schedule.add_recurrence_rule IceCube::Rule.monthly(repeat_interval)
#     end
#     schedule
#   end

#   # Method to generate occurrences for recurring reminders
#   def recurring_occurrences(start_time, end_time)
#     recurring_schedule.occurrences_between(start_time, end_time)
#   end

#   scope :special_events, -> { where(is_special_event: true) }
# end
class Reminder < ApplicationRecord
  belongs_to :user
  has_many :reminder_users, dependent: :destroy
  has_many :users, through: :reminder_users
  has_one :notification
  has_one_attached :attachment
  has_many :invitations
  has_many :invited_users, through: :invitations, source: :user
  has_many :tagged_users, through: :reminder_users, source: :user

  after_create :create_notification

  validates :user_id, presence: true, unless: -> { user.nil? }
  validates :title, :due_date, :duration, presence: true
  validates :repeat_interval_unit, inclusion: { in: %w(day week month) }, allow_blank: true
  validates :repeat_interval, presence: true, if: -> { repeat_interval_unit.present? }
  validate :due_date_cannot_be_in_the_past

  def add_user(user, relationship_category)
    reminder_users.create(user: user, relationship_category: relationship_category)
  end

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
    return nil unless repeat_interval.present? && repeat_interval_unit.present?

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
# Virtual attributes for custom interval
attr_accessor :custom_interval_value, :custom_interval_unit

# Validation for custom interval
validates :custom_interval_value, presence: true, if: -> { custom_interval_unit.present? }

# Method to calculate next occurrence based on custom interval
def next_occurrence
  case custom_interval_unit
  when 'days'
    due_date + custom_interval_value.days
  when 'weeks'
    due_date + custom_interval_value.weeks
  when 'months'
    due_date + custom_interval_value.months
  else
    raise ArgumentError, "Unsupported custom interval unit: #{custom_interval_unit}"
  end
end
  # Method to generate occurrences for recurring reminders
  def recurring_occurrences(start_time, end_time)
    return [] unless recurring_schedule.present?

    recurring_schedule.occurrences_between(start_time, end_time)
  end

  scope :special_events, -> { where(is_special_event: true) }
end
