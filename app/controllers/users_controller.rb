# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.select(:id, :name, :email).all
    render json: @users
  end

  def search
    query = params[:q] || params[:email]

    if query.present?
      @users = User.select(:id, :name, :email)
                   .where("name LIKE ? OR email LIKE ?", "%#{query}%", "%#{query}%")
                   .where.not(id: current_user.id) # exclude self
                   .limit(20)
    else
      @users = []
    end

    render json: @users
  end
end