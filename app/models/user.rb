
class User < ActiveRecord::Base
  has_many :reminders
  has_many :notes
  has_many :notifications
 
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  include DeviseTokenAuth::Concerns::User
  enum role: [:user, :admin] # Define roles as enum


  def self.search(query)
    where("email LIKE ? OR username LIKE ?", "%#{query}%", "%#{query}%")
  end
  has_many :sent_friend_requests, class_name: 'FriendRequest', foreign_key: 'sender_id'

  # Association for received friend requests
  has_many :received_friend_requests, class_name: 'FriendRequest', foreign_key: 'receiver_id'
end

