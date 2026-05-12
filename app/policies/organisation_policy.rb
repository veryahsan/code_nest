# frozen_string_literal: true

# Authorisation rules for the tenant-facing Organisation CRUD. Super
# admins manage every organisation through Active Admin; regular tenant
# users can only see / edit their own org, and only org admins may
# update or destroy it.
class OrganisationPolicy < ApplicationPolicy
  include TenantPolicy

  def show?
    same_org? || super_admin?
  end

  def update?
    admin_of_same_org?
  end

  def edit?
    update?
  end

  def destroy?
    admin_of_same_org? && record.users.count <= 1
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?
      return scope.where(id: user.organisation_id) if user&.organisation_id

      scope.none
    end
  end
end
