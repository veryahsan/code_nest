# frozen_string_literal: true

# Tenant-side CRUD for the user's own Organisation.
#
#   * #new / #create — bootstrap path for a freshly-confirmed user that
#     hasn't been auto-attached to an existing org. Delegates to
#     Organisations::CreationFacade.
#   * #show / #edit / #update / #destroy — operate on the org the
#     current user already belongs to. Pundit authorises each action;
#     destroy is admin-only and refuses when the org still has users.
class OrganisationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_for_creation, only: %i[new create]
  before_action :load_for_management, only: %i[show edit update destroy]

  def new; end

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

  def show; end

  def edit; end

  def update
    result = Organisations::UpdateFacade.call(
      organisation: @organisation,
      attributes: organisation_update_params,
    )

    if result.success?
      redirect_to organisation_path(@organisation), notice: "Organisation updated."
    else
      @organisation = result.error
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = Organisations::DeletionService.call(organisation: @organisation)
    if result.success?
      sign_out(current_user) if current_user.organisation_id.nil?
      redirect_to root_path, notice: "Organisation deleted.", status: :see_other
    else
      redirect_to organisation_path(@organisation), alert: result.error, status: :see_other
    end
  end

  private

  def load_for_creation
    return redirect_to(dashboard_path) unless current_user.organisation.blank? && !current_user.super_admin?

    @organisation = Organisation.new
  end

  def load_for_management
    @organisation = Organisation.find(params[:id])
    authorize @organisation
  end

  def organisation_params
    params.require(:organisation).permit(:name)
  end

  def organisation_update_params
    params.require(:organisation).permit(:name, :slug)
  end
end
