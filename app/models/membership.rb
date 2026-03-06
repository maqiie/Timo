# class Membership < ApplicationRecord
#   belongs_to :user
#   belongs_to :organization

#   enum role: [:organization_admin, :worker]

#   validates :organization_id, presence: true
#   validates :user_id, uniqueness: { scope: :organization_id }  # Example uniqueness constraint
# end
class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :user_id, presence: true
  validates :organization_id, presence: true
end
