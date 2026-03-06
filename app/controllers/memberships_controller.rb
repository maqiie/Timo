# class MembershipsController < ApplicationController
#     before_action :set_user
  
#     def index
#       memberships = @user.memberships
#       render json: memberships
#     end
  
#     def create
#         @organization = Organization.find(params[:organization_id])
#         @user = User.find(params[:user_id])
    
#         # Assuming you want to add the user as a member with a default role like 'worker'
#         @membership = Membership.new(user: @user, organization: @organization, role: 'worker')
    
#         if @membership.save
#           render json: @membership, status: :created
#         else
#           render json: @membership.errors, status: :unprocessable_entity
#         end
#       end
#     def destroy
#       membership = @user.memberships.find(params[:id])
#       membership.destroy
#       head :no_content
#     end
  
#     private
  
#     def set_user
#       @user = User.find(params[:user_id])
#     end
#   end
class MembershipsController < ApplicationController
    # POST /organizations/:organization_id/memberships
    def create
      @organization = Organization.find(params[:organization_id])
      @membership = @organization.memberships.build(membership_params)
  
      if @membership.save
        render json: @membership, status: :created
      else
        render json: @membership.errors, status: :unprocessable_entity
      end
    end
  
    private
  
    def membership_params
      params.require(:membership).permit(:user_id, :role)
    end
  end
  
  
  