# frozen_string_literal: true

class IssuePolicy < ApplicationPolicy
  include TenantPolicy

  def index?
    can_view_project_issues?
  end

  def show?
    can_view_project_issues?
  end

  def create?
    lead_for_project?
  end

  def update?
    lead_for_project?
  end

  def destroy?
    lead_for_project?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?
      return scope.none unless user&.organisation_id

      org_scope = scope.joins(:project).where(projects: { organisation_id: user.organisation_id })
      return org_scope if user.org_admin?

      org_scope.where(project_id: user.project_memberships.select(:project_id))
    end
  end

  private

  def project
    record.is_a?(Class) ? nil : record.project
  end

  def can_view_project_issues?
    return false unless project

    ProjectPolicy.new(user, project).show?
  end

  def lead_for_project?
    return false unless project
    return false unless member_of_same_org?(project)

    user.lead_for_project?(project)
  end
end
