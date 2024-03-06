class Note < ApplicationRecord
    belongs_to :user
    has_one :reminder
  end
  