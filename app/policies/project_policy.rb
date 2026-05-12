# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  include TenantPolicy

  def index?
    user&.organisation_id.present? || super_admin?
  end

  def show?
    member_of_same_org?
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
      return scope.where(organisation_id: user.organisation_id) if user&.organisation_id

      scope.none
    end
  end
end
