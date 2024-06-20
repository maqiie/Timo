
  # class InvitationsController < ApplicationController
  #   before_action :set_invitation, only: [:accept, :decline]
  #   def index
  #     @invitations = current_user.invitations.includes(:reminder, :sender)
      
  #     render json: @invitations.as_json(
  #       include: {
  #         sender: { only: [:id, :name, :email] },       # Include sender details
  #         reminder: { only: [:id, :title, :description, :due_date, :location] }  # Include reminder details
  #       },
  #       only: [:id, :status, :created_at, :updated_at]  # Include invitation details
  #     ), status: :ok
  #   end
    
    
  #   def create
  #   unless current_user
  #     render json: { error: 'User not authenticated' }, status: :unauthorized
  #     return
  #   end

  #   @invitation = Invitation.new(invitation_params)
  #   @invitation.sender_id = current_user.id

  #   if @invitation.save
  #     InvitationMailer.invitation_email(@invitation, current_user).deliver_later

  #     notify_creator('created')

  #     render json: @invitation, status: :created
  #   else
  #     render json: @invitation.errors, status: :unprocessable_entity
  #   end
  # end
  
  #   def accept
  #     if @invitation.update(status: 'accepted')
  #       create_reminder_user(@invitation.reminder_id, @invitation.user_id)
  #       notify_creator('accepted')
  #       render json: { message: 'Invitation accepted' }, status: :ok
  #     else
  #       render json: @invitation.errors, status: :unprocessable_entity
  #     end
  #   end
  
  #   def decline
  #     if @invitation.update(status: 'declined')
  #       notify_creator('declined')
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
  
  #   def notify_creator(action)
  #     sender = User.find(current_user.id)
  #     message = case action
  #               when 'created'
  #                 "#{sender.name} created an invitation."
  #               when 'accepted'
  #                 "#{sender.name} accepted your invitation."
  #               when 'declined'
  #                 "#{sender.name} declined your invitation."
  #               else
  #                 "#{sender.name} performed an action on your invitation."
  #               end
  
  #     ActionCable.server.broadcast "notifications_#{current_user.id}", { message: message }
  #   end
  
  #   def create_reminder_user(reminder_id, user_id)
  #     ReminderUser.create(reminder_id: reminder_id, user_id: user_id)
  #   end
  # end
  class InvitationsController < ApplicationController
    before_action :set_invitation, only: [:accept, :decline, :update]
  
    def index
      @invitations = current_user.invitations.includes(:reminder, :sender)
      
      render json: @invitations.as_json(
        include: {
          sender: { only: [:id, :name, :email] },       # Include sender details
          reminder: { only: [:id, :title, :description, :due_date, :location] }  # Include reminder details
        },
        only: [:id, :status, :created_at, :updated_at]  # Include invitation details
      ), status: :ok
    end
  
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
        create_reminder_user(@invitation.reminder_id, @invitation.user_id) if @invitation.reminder_id.present?
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
  
    def update
      if @invitation.update(invitation_params)
        if @invitation.rescheduled?
          notify_creator('rescheduled')
          InvitationMailer.invitation_email(@invitation, current_user).deliver_later
        end
        render json: @invitation, status: :ok
      else
        render json: @invitation.errors, status: :unprocessable_entity
      end
    end
  
    private
  
    def set_invitation
      @invitation = Invitation.find(params[:id])
    end
  
    def invitation_params
      params.require(:invitation).permit(:user_id, :reminder_id, :status, :scheduled_at)
    end
  
    def notify_creator(action, invitation)
      sender = User.find(current_user.id)
      creator = invitation.creator # Assuming `creator` method returns the creator of the invitation
    
      message = case action
                when 'created'
                  "#{sender.name} created an invitation."
                when 'accepted'
                  "#{sender.name} accepted your invitation."
                when 'declined'
                  "#{sender.name} declined your invitation."
                when 'rescheduled'
                  "#{sender.name} rescheduled the invitation."
                else
                  "#{sender.name} performed an action on your invitation."
                end
    
      # Broadcast the message to the creator's notifications channel
      ActionCable.server.broadcast "notifications_#{creator.id}", { message: message }
    end
    
  
    def create_reminder_user(reminder_id, user_id)
      ReminderUser.create(reminder_id: reminder_id, user_id: user_id)
    end
  end
  