# frozen_string_literal: true

# Assembles every piece of data the dashboard view needs for a given user.
# The controller becomes a one-liner; all query/branching logic lives here.
#
# #mode tells the view which partial to render and is one of
# :onboarding, :admin_analytics, or :member_workspace.
#
# In :admin_analytics mode the readers cover the whole organisation
# (org-wide teams/projects/invitations + counters + top-N collections).
# In :member_workspace mode the readers are scoped to the signed-in user
# (only their teams, only projects belonging to those teams, plus their
# employee record and direct reports).
class DashboardFacade < ApplicationFacade
  attr_reader :user, :organisation,
              :teams, :projects, :pending_invitations,
              :employee, :manager, :direct_reports,
              :greeting_name, :role_label, :job_title,
              :members_total, :admins_count, :members_count,
              :teams_total, :projects_total, :employees_total,
              :unassigned_projects_count, :users_without_team_count,
              :employees_without_manager_count,
              :pending_invitations_count, :accepted_invitations_count,
              :new_users_last_7d, :new_projects_last_7d, :new_teams_last_7d,
              :top_teams_by_members, :top_teams_by_projects

  def initialize(user:)
    @user = user
  end

  def call
    @organisation  = @user.organisation
    @greeting_name = @user.email.to_s.split("@").first
    return success(self) if onboarding?
    if @user.org_admin?
      load_admin_analytics
    else
      load_member_workspace
    end

    success(self)
  end

  def onboarding?
    @organisation.nil?
  end

  def mode
    return :onboarding if onboarding?

    @user.org_admin? ? :admin_analytics : :member_workspace
  end

  def direct_reports?
    direct_reports.present? && direct_reports.any?
  end

  private

  def load_org_workspace
    @teams = @organisation.teams.order(:name).includes(:users)
    @projects = @organisation.projects.order(:name).includes(:team)
    @pending_invitations = @organisation.invitations.pending
                                        .order(created_at: :desc)
                                        .limit(10)
  end

  def load_member_workspace
    @teams    = @user.teams.order(:name).includes(:users)
    @projects = @organisation.projects
                              .where(team_id: @teams.select(:id))
                              .order(:name).includes(:team)
    @employee       = @user.employee
    @manager        = @employee&.manager
    @job_title      = @employee&.job_title
    @direct_reports = @employee&.direct_reports&.includes(:user) || []
    @role_label     = "Member"
  end

  def load_admin_analytics
    load_org_workspace

    users_scope       = @organisation.users
    teams_scope       = @organisation.teams
    projects_scope    = @organisation.projects
    employees_scope   = @organisation.employees
    invitations_scope = @organisation.invitations

    @members_total = users_scope.count
    @admins_count  = users_scope.where(org_role: :admin).count
    @members_count = users_scope.where(org_role: :member).count

    @teams_total     = teams_scope.count
    @projects_total  = projects_scope.count
    @employees_total = employees_scope.count

    @unassigned_projects_count       = projects_scope.where(team_id: nil).count
    @users_without_team_count        = users_scope.left_outer_joins(:team_memberships)
                                                  .where(team_memberships: { id: nil })
                                                  .count
    @employees_without_manager_count = employees_scope.where(manager_id: nil).count

    @pending_invitations_count  = invitations_scope.pending.count
    @accepted_invitations_count = invitations_scope.accepted.count

    since = 7.days.ago
    @new_users_last_7d    = users_scope.where("created_at >= ?", since).count
    @new_projects_last_7d = projects_scope.where("created_at >= ?", since).count
    @new_teams_last_7d    = teams_scope.where("created_at >= ?", since).count

    @top_teams_by_members = teams_scope
                              .left_joins(:team_memberships)
                              .group("teams.id")
                              .select("teams.*, COUNT(team_memberships.id) AS team_members_count")
                              .order(Arel.sql("COUNT(team_memberships.id) DESC"), :name)
                              .limit(5)

    @top_teams_by_projects = teams_scope
                               .left_joins(:projects)
                               .group("teams.id")
                               .select("teams.*, COUNT(projects.id) AS team_projects_count")
                               .order(Arel.sql("COUNT(projects.id) DESC"), :name)
                               .limit(5)
  end
end
