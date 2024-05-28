# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications
    logger.info "Notifications loaded for user #{current_user.id}: #{@notifications.inspect}"
    render json: @notifications
  rescue => e
    logger.error "Failed to load notifications: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: 'Failed to load notifications' }, status: :internal_server_error
  end
end
