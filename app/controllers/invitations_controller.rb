# frozen_string_literal: true

# Tenant-side management for outbound Invitations. Org admins can list
# pending invites, send new ones, and revoke unaccepted ones. Acceptance
# happens on a separate, public controller (InvitationAcceptancesController).
class InvitationsController < ApplicationController
  include TenantScoped

  before_action :require_organisation_admin!
  before_action :load_invitation, only: %i[destroy]

  def index
    authorize Invitation
    @pending = current_organisation.invitations.pending.order(created_at: :desc)
    @accepted = current_organisation.invitations.accepted.order(created_at: :desc).limit(20)
  end

  def new
    @invitation = current_organisation.invitations.new
    authorize @invitation
  end

  def create
    @invitation = current_organisation.invitations.new
    authorize @invitation

    result = Invitations::CreationFacade.call(
      organisation: current_organisation,
      inviter: current_user,
      attributes: invitation_params,
    )

    if result.success?
      redirect_to invitations_path, notice: "Invitation sent to #{result.value.email}."
    else
      @invitation = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    result = Invitations::RevokeService.call(invitation: @invitation)
    if result.success?
      redirect_to invitations_path, notice: "Invitation revoked.", status: :see_other
    else
      redirect_to invitations_path, alert: result.error, status: :see_other
    end
  end

  private

  def load_invitation
    @invitation = current_organisation.invitations.find(params[:id])
    authorize @invitation
  end

  def invitation_params
    params.require(:invitation).permit(:email, :org_role, :expires_at)
  end
end
