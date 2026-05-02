# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_org_workspace!

  def show
    @organisation = current_user.organisation
    @teams = @organisation.teams.order(:name).includes(:users)
    @projects = @organisation.projects.order(:name).includes(:team)
    @pending_invitations = @organisation.invitations.pending.order(created_at: :desc).limit(10)
  end

  private

  def ensure_org_workspace!
    if current_user.super_admin?
      redirect_to admin_root_path
      return
    end

    return if current_user.organisation.present?

    redirect_to root_path, alert: "Your account is not linked to an organisation."
  end
end
