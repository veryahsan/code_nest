# frozen_string_literal: true

# Assembles every piece of data the dashboard view needs for a given user.
# The controller becomes a one-liner; all query/branching logic lives here.
#
# #mode tells the view which partial to render and is one of
# :onboarding, :admin_analytics, or :member_workspace.
#
# In :admin_analytics mode the readers cover the whole organisation
# (org-wide projects/invitations + counters + top-N collections).
# In :member_workspace mode the readers are scoped to the signed-in user
# (only the projects they belong to, plus their employee record and direct
# reports).
class DashboardFacade < ApplicationFacade
  attr_reader :user, :organisation,
              :projects, :pending_invitations,
              :employee, :manager, :direct_reports,
              :greeting_name, :role_label, :job_title,
              :members_total, :admins_count, :members_count,
              :projects_total, :employees_total,
              :projects_without_members_count, :users_without_project_count,
              :employees_without_manager_count,
              :pending_invitations_count, :accepted_invitations_count,
              :new_users_last_7d, :new_projects_last_7d,
              :top_projects_by_members

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
    @projects = @organisation.projects.order(:name).includes(:users)
    @pending_invitations = @organisation.invitations.pending
                                        .includes(invited_by: { avatar_attachment: :blob })
                                        .order(created_at: :desc)
                                        .limit(10)
  end

  def load_member_workspace
    @projects = @user.projects.order(:name).includes(:users)
    @employee       = Employee.includes(manager: { user: { avatar_attachment: :blob } })
                              .find_by(user: @user)
    @manager        = @employee&.manager
    @job_title      = @employee&.job_title
    @direct_reports = @employee&.direct_reports&.includes(user: { avatar_attachment: :blob }) || []
    @role_label     = "Member"
  end

  def load_admin_analytics
    load_org_workspace

    users_scope       = @organisation.users
    projects_scope    = @organisation.projects
    employees_scope   = @organisation.employees
    invitations_scope = @organisation.invitations

    @members_total = users_scope.count
    @admins_count  = users_scope.where(org_role: :admin).count
    @members_count = users_scope.where(org_role: :member).count

    @projects_total  = projects_scope.count
    @employees_total = employees_scope.count

    @projects_without_members_count  = projects_scope.left_outer_joins(:project_memberships)
                                                     .where(project_memberships: { id: nil })
                                                     .count
    @users_without_project_count     = users_scope.left_outer_joins(:project_memberships)
                                                  .where(project_memberships: { id: nil })
                                                  .count
    @employees_without_manager_count = employees_scope.where(manager_id: nil).count

    @pending_invitations_count  = invitations_scope.pending.count
    @accepted_invitations_count = invitations_scope.accepted.count

    since = 7.days.ago
    @new_users_last_7d    = users_scope.where("created_at >= ?", since).count
    @new_projects_last_7d = projects_scope.where("created_at >= ?", since).count

    @top_projects_by_members = projects_scope
                                 .left_joins(:project_memberships)
                                 .group("projects.id")
                                 .select("projects.*, COUNT(project_memberships.id) AS project_members_count")
                                 .order(Arel.sql("COUNT(project_memberships.id) DESC"), :name)
                                 .limit(5)
  end
end
