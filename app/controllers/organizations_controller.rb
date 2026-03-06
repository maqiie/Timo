class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [:show, :add_worker]


  def index
  end
  def show
    @workers = @organization.users.where(role: 'worker')
    @tasks = @organization.reminders
  end

  def add_worker
    worker = User.find_by(email: params[:email])
    if worker
      Membership.create(user: worker, organization: @organization, role: 'worker')
      redirect_to @organization, notice: 'Worker added successfully.'
    else
      redirect_to @organization, alert: 'Worker not found.'
    end
  end

  private

  def set_organization
    @organization = current_user.organization
  end
end
