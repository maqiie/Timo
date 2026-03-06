class Organization < ApplicationRecord
    has_many :users
    has_many :memberships
    has_many :reminders
    
    validates :name, presence: true, uniqueness: true
  end
  