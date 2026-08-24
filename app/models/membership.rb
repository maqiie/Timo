
# class Membership < ApplicationRecord
#   belongs_to :user
#   belongs_to :organization

#   validates :user_id, presence: true
#   validates :organization_id, presence: true
# end
class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :user_id, presence: true
  validates :organization_id, presence: true
  validates :user_id, uniqueness: { scope: :organization_id, message: "is already a member of this organization" }
end