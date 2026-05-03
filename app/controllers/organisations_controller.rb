# frozen_string_literal: true

# Tenant bootstrap for confirmed users who didn't get auto-attached to an
# existing organisation by domain match. The actual creation flow lives in
# Organisations::CreationFacade — this controller is intentionally thin.
class OrganisationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_can_create_organisation!

  def new
    @organisation = Organisation.new
  end

  def create
    result = Organisations::CreationFacade.call(
      name: organisation_params[:name],
      owner: current_user,
    )

    if result.success?
      redirect_to dashboard_path,
                  notice: "Welcome to #{result.value.name}. You're now its administrator."
    else
      @organisation = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def ensure_can_create_organisation!
    return if current_user.organisation.blank? && !current_user.super_admin?

    redirect_to dashboard_path
  end

  def organisation_params
    params.require(:organisation).permit(:name)
  end
end
