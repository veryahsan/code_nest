# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  include TenantPolicy

  def index?
    admin_of_same_org?(user&.organisation)
  end

  def show?
    admin_of_same_org?
  end

  def create?
    admin_of_same_org?(user&.organisation)
  end

  def destroy?
    admin_of_same_org?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?

      if user&.organisation_id && user.org_admin?
        return scope.where(organisation_id: user.organisation_id)
      end

      scope.none
    end
  end
end
