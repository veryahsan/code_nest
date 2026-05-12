# frozen_string_literal: true

class TeamMembershipPolicy < ApplicationPolicy
  include TenantPolicy

  def create?
    admin_of_same_org?(record.team)
  end

  def destroy?
    admin_of_same_org?(record.team)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?
      return scope.joins(:team).where(teams: { organisation_id: user.organisation_id }) if user&.organisation_id

      scope.none
    end
  end
end
