class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [:show, :add_worker]

  def index
    @organizations = current_user.organizations
    render json: @organizations
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      Membership.create!(user: current_user, organization: @organization, role: 'admin')
      render json: @organization, status: :created
    else
      render json: { errors: @organization.errors.full_messages }, status: :unprocessable_entity
    end
  end

def show
  memberships = @organization.memberships.includes(:user)
  tasks       = @organization.reminders

  render json: {
    organization: @organization,
    memberships: memberships.map { |m|
      { id: m.id, role: m.role, user: { id: m.user.id, name: m.user.name, email: m.user.email } }
    },
    tasks: tasks
  }
end

  def add_worker
    worker = User.find_by(email: params[:email])

    if worker
      Membership.create(user: worker, organization: @organization, role: 'worker')
      render json: { message: 'Worker added successfully.' }, status: :ok
    else
      render json: { error: 'Worker not found.' }, status: :not_found
    end
  end

  private

  def set_organization
    @organization = current_user.organizations.find(params[:id])
  end

  def organization_params
  params.require(:organization).permit(:name, :description, :category, :website)
end
end