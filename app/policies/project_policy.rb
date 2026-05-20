# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  include TenantPolicy

  def index?
    user&.organisation_id.present? || super_admin?
  end

  def show?
    return true if admin_of_same_org?
    return false unless member_of_same_org?
    return false if record.team_id.blank?

    user.team_memberships.exists?(team_id: record.team_id)
  end

  def create?
    admin_of_same_org?(user&.organisation)
  end

  def update?
    admin_of_same_org?
  end

  def destroy?
    admin_of_same_org?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?
      return scope.none unless user&.organisation_id

      org_scope = scope.where(organisation_id: user.organisation_id)
      return org_scope if user.org_admin?

      org_scope.where(team_id: user.team_memberships.select(:team_id))
    end
  end
end
