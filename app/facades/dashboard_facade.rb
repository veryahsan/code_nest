# frozen_string_literal: true

# Assembles every piece of data the dashboard view needs for a given user.
# The controller becomes a one-liner; all query/branching logic lives here.
#
# #onboarding? tells the view which partial to render.
# When false, #organisation, #teams, #projects, and #pending_invitations
# are guaranteed to be present.
class DashboardFacade < ApplicationFacade
  attr_reader :organisation, :teams, :projects, :pending_invitations

  def initialize(user:)
    @user = user
  end

  def call
    @organisation = @user.organisation

    if onboarding?
      success(self)
    else
      load_workspace
      success(self)
    end
  end

  def onboarding?
    @organisation.nil?
  end

  private

  def load_workspace
    @teams = @organisation.teams.order(:name).includes(:users)
    @projects = @organisation.projects.order(:name).includes(:team)
    @pending_invitations = @organisation.invitations.pending
                                        .order(created_at: :desc)
                                        .limit(10)
  end
end
