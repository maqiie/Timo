class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.upcoming
    render json: { notifications: @notifications.select { |n| n.reminder.due_date > Time.current } }
  rescue => e
    render json: { error: "Failed to fetch notifications: #{e.message}" }, status: :internal_server_error
  end
end
