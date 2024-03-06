
class User < ActiveRecord::Base
  has_many :reminders
  has_many :notes
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  include DeviseTokenAuth::Concerns::User
  enum role: [:user, :admin] # Define roles as enum
end

