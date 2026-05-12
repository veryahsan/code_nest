# frozen_string_literal: true

# Public-facing endpoint for invitees to accept their invitation.
# `show` previews the invitation; `create` finalises acceptance and
# (for new accounts) sets a password.
class InvitationAcceptancesController < ApplicationController
  before_action :load_invitation
  before_action :reject_if_finalised

  def show
    @existing_user = User.find_by(email: @invitation.email)
  end

  def create
    result = Invitations::AcceptFacade.call(
      token: @invitation.token,
      password: params.dig(:invitation_acceptance, :password),
    )

    if result.success?
      sign_in(result.value)
      redirect_to dashboard_path,
                  notice: "Welcome to #{@invitation.organisation.name}."
    else
      flash.now[:alert] = result.error
      @existing_user = User.find_by(email: @invitation.email)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def load_invitation
    @invitation = Invitation.find_by(token: params[:token])
    return if @invitation

    redirect_to root_path, alert: "Invitation link is invalid or has been revoked."
  end

  def reject_if_finalised
    return unless @invitation

    if @invitation.accepted?
      redirect_to root_path, alert: "This invitation has already been accepted."
    elsif @invitation.expires_at && @invitation.expires_at <= Time.current
      redirect_to root_path, alert: "This invitation has expired."
    end
  end
end
