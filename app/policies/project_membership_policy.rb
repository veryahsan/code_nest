# frozen_string_literal: true

class ProjectMembershipPolicy < ApplicationPolicy
  include TenantPolicy

  def create?
    admin_of_same_org?(record.project)
  end

  def destroy?
    admin_of_same_org?(record.project)
  end

  def promote_lead?
    admin_of_same_org?(record.project)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?
      return scope.joins(:project).where(projects: { organisation_id: user.organisation_id }) if user&.organisation_id

      scope.none
    end
  end
end
