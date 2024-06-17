
  # class InvitationsController < ApplicationController
  #   before_action :set_invitation, only: [:accept, :decline]
  
  #   def create
  #     @invitation = Invitation.new(invitation_params)
  #     @invitation.sender_id = current_user.id
  
  #     if @invitation.save
  #       # Call the mailer method to send the email
  #       InvitationMailer.invitation_email(@invitation, current_user).deliver_now # or deliver_later
  #       render json: @invitation, status: :created
  #     else
  #       render json: @invitation.errors, status: :unprocessable_entity
  #     end
  #   end
  
  #   def accept
  #     if @invitation.update(status: 'accepted')
  #       ReminderUser.create(reminder_id: @invitation.reminder_id, user_id: @invitation.user_id)
  #       notify_creator(@invitation.sender_id)
  #       render json: { message: 'Invitation accepted' }, status: :ok
  #     else
  #       render json: @invitation.errors, status: :unprocessable_entity
  #     end
  #   end
  
  #   def decline
  #     if @invitation.update(status: 'declined')
  #       # Notify the creator that the invitation was declined
  #       notify_creator(@invitation.sender_id, declined: true)
  #       render json: { message: 'Invitation declined' }, status: :ok
  #     else
  #       render json: @invitation.errors, status: :unprocessable_entity
  #     end
  #   end
  
  #   private
  
  #   def set_invitation
  #     @invitation = Invitation.find(params[:id])
  #   end
  
  #   def invitation_params
  #     params.require(:invitation).permit(:user_id, :reminder_id, :status)
  #   end
  
  #   def notify_creator(sender_id, declined: false)
  #     sender = User.find(sender_id)
  #     message = declined ? 'User declined your invitation' : 'User accepted your invitation'
  
  #     ActionCable.server.broadcast "notifications_#{sender_id}", { message: message }
  #   end
  # end
  class InvitationsController < ApplicationController
    before_action :set_invitation, only: [:accept, :decline]
  
    def create
    unless current_user
      render json: { error: 'User not authenticated' }, status: :unauthorized
      return
    end

    @invitation = Invitation.new(invitation_params)
    @invitation.sender_id = current_user.id

    if @invitation.save
      InvitationMailer.invitation_email(@invitation, current_user).deliver_later

      notify_creator('created')

      render json: @invitation, status: :created
    else
      render json: @invitation.errors, status: :unprocessable_entity
    end
  end
  
    def accept
      if @invitation.update(status: 'accepted')
        create_reminder_user(@invitation.reminder_id, @invitation.user_id)
        notify_creator('accepted')
        render json: { message: 'Invitation accepted' }, status: :ok
      else
        render json: @invitation.errors, status: :unprocessable_entity
      end
    end
  
    def decline
      if @invitation.update(status: 'declined')
        notify_creator('declined')
        render json: { message: 'Invitation declined' }, status: :ok
      else
        render json: @invitation.errors, status: :unprocessable_entity
      end
    end
  
    private
  
    def set_invitation
      @invitation = Invitation.find(params[:id])
    end
  
    def invitation_params
      params.require(:invitation).permit(:user_id, :reminder_id, :status)
    end
  
    def notify_creator(action)
      sender = User.find(current_user.id)
      message = case action
                when 'created'
                  "#{sender.name} created an invitation."
                when 'accepted'
                  "#{sender.name} accepted your invitation."
                when 'declined'
                  "#{sender.name} declined your invitation."
                else
                  "#{sender.name} performed an action on your invitation."
                end
  
      ActionCable.server.broadcast "notifications_#{current_user.id}", { message: message }
    end
  
    def create_reminder_user(reminder_id, user_id)
      ReminderUser.create(reminder_id: reminder_id, user_id: user_id)
    end
  end
  