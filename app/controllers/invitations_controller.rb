# app/controllers/invitations_controller.rb
class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invitation, only: [:accept, :decline, :update]

  rescue_from ActiveRecord::RecordNotFound,  with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid,   with: :record_invalid
  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique
  rescue_from ArgumentError,                 with: :argument_error

  def index
    # Return BOTH received (user_id) AND sent (sender_id) invitations
    @invitations = Invitation
      .where(user_id: current_user.id)
      .or(Invitation.where(sender_id: current_user.id))
      .includes(:reminder, :sender, :user)
      .order(created_at: :desc)

    render json: @invitations.as_json(
      include: {
        sender:   { only: [:id, :name, :email] },
        user:     { only: [:id, :name, :email] },
        reminder: { only: [:id, :title, :description, :due_date, :location, :priority, :notes] }
      },
      only: [:id, :status, :created_at, :updated_at, :user_id, :sender_id, :reminder_id]
    ), status: :ok
  end

  def create
    @invitation = Invitation.new(invitation_params)
    @invitation.sender_id = current_user.id

    if @invitation.save
      InvitationMailer.invitation_email(@invitation, current_user).deliver_later
      notify_creator('created', @invitation)
      render json: @invitation.as_json(
        include: {
          sender:   { only: [:id, :name, :email] },
          reminder: { only: [:id, :title, :description, :due_date, :location, :priority, :notes] }
        },
        only: [:id, :status, :created_at, :updated_at, :user_id, :sender_id, :reminder_id]
      ), status: :created
    else
      render json: { error: @invitation.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def accept
    if overlapping_reminder_present?
      render json: { error: 'Overlapping reminder present' }, status: :unprocessable_entity
    else
      ActiveRecord::Base.transaction do
        @invitation.update!(status: 'accepted')
        reminder = @invitation.reminder
        reminder.update!(label: "<Tagged by '#{current_user.name}'>")
        current_user.reminders << reminder
      end

      ActionCable.server.broadcast "notifications_#{@invitation.sender_id}", {
        message: "#{current_user.name} accepted your invitation.",
        invitation: @invitation
      }
      ActionCable.server.broadcast "invitations_channel", @invitation
      render json: @invitation, status: :ok
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def decline
    ActiveRecord::Base.transaction do
      @invitation.update!(status: 'declined')
      notify_creator('declined', @invitation)
    end
    render json: { message: 'Invitation declined' }, status: :ok
  end

  def update
    if @invitation.update(invitation_params)
      notify_creator('rescheduled', @invitation) if @invitation.rescheduled?
      render json: @invitation, status: :ok
    else
      render json: { error: @invitation.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find(params[:id])
    unless @invitation.user_id == current_user.id || @invitation.sender_id == current_user.id
      render json: { error: 'Not authorized' }, status: :forbidden
    end
  end

  def invitation_params
    params.require(:invitation).permit(:user_id, :reminder_id, :status, :scheduled_at)
  end

  def overlapping_reminder_present?
    reminder = Reminder.find(@invitation.reminder_id)
    reminder_end_time = reminder.due_date + reminder.duration.to_i.minutes
    current_user.reminders.where.not(id: reminder.id).any? do |r|
      r_end = r.due_date + r.duration.to_i.minutes
      reminder.due_date.between?(r.due_date, r_end) ||
      reminder_end_time.between?(r.due_date, r_end) ||
      r.due_date.between?(reminder.due_date, reminder_end_time) ||
      r_end.between?(reminder.due_date, reminder_end_time)
    end
  end

  def notify_creator(action, invitation)
    creator = invitation.sender
    message = case action
              when 'created'     then "#{current_user.name} created an invitation."
              when 'accepted'    then "#{current_user.name} accepted your invitation."
              when 'declined'    then "#{current_user.name} declined your invitation."
              when 'rescheduled' then "#{current_user.name} rescheduled the invitation."
              else "#{current_user.name} performed an action on your invitation."
              end
    ActionCable.server.broadcast "notifications_#{creator.id}", { message: message, invitation: invitation }
  end

  def create_reminder_user(reminder_id, user_id)
    ReminderUser.create!(reminder_id: reminder_id, user_id: user_id)
  end

  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def record_invalid(exception)
    render json: { error: exception.message }, status: :unprocessable_entity
  end

  def record_not_unique(exception)
    render json: { error: 'Record not unique. Please check your input.' }, status: :unprocessable_entity
  end

  def argument_error(exception)
    render json: { error: exception.message }, status: :unprocessable_entity
  end
end