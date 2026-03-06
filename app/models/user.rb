
class User < ActiveRecord::Base
  # Associations
  has_one_attached :image
  has_many :reminders
  has_many :reminder_users
  has_many :tagged_reminders, through: :reminder_users, source: :reminder
  has_many :notes
  has_many :notifications
  has_many :invitations
  has_many :invited_reminders, through: :invitations, source: :reminder
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  belongs_to :organization, optional: true

  # Enum for roles
  enum role: [:personal, :organization_admin, :worker]

  # Ensure `organization_registration` is accessible
  attr_accessor :organization_registration

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  include DeviseTokenAuth::Concerns::User

# Callback to create organization if organization admin
after_create :create_organization_if_organization_admin

attr_accessor :organization_registration

def organization_registration?
  organization_registration == 'true' || organization_registration == true
end

def create_organization_if_organization_admin
  return unless organization_registration?

  ActiveRecord::Base.transaction do
    organization = Organization.create!(name: "#{name}'s Organization")
    Membership.create!(user: self, organization: organization, role: 'admin') # Assuming the role is admin for the creator
  end
end
  # Method for searching users
  def self.search(query)
    where("email LIKE ? OR username LIKE ?", "%#{query}%", "%#{query}%")
  end

  # Associations for friend requests
  has_many :sent_friend_requests, class_name: 'FriendRequest', foreign_key: 'sender_id'
  has_many :received_friend_requests, class_name: 'FriendRequest', foreign_key: 'receiver_id'

  # JSON serialization method
  def as_json(options = {})
    super(options.merge({ only: [:id, :email, :username, :name, :nickname, :birthday, :role, :uid], methods: [:image_url] }))
  end

  # Method to get image URL
  def image_url
    image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(image, only_path: true) : nil
  end
end



