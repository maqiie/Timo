class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_admin!, only: [:create]

  # POST /organizations/:organization_id/memberships
  def create
    @membership = @organization.memberships.build(membership_params)

    if @membership.save
      render json: @membership, status: :created
    else
      render json: { errors: @membership.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def authorize_admin!
    membership = current_user.memberships.find_by(organization: @organization, role: 'admin')
    render json: { error: 'Not authorized' }, status: :forbidden unless membership
  end

  def membership_params
    params.permit(:user_id, :role)
  end
end