# frozen_string_literal: true

class ProjectDocumentPolicy < ApplicationPolicy
  include TenantPolicy

  def index?
    member_of_same_org?(record_or_project)
  end

  def show?
    member_of_same_org?(record_or_project)
  end

  def create?
    admin_of_same_org?(record_or_project)
  end

  def update?
    admin_of_same_org?(record_or_project)
  end

  def destroy?
    admin_of_same_org?(record_or_project)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?
      return scope.joins(:project).where(projects: { organisation_id: user.organisation_id }) if user&.organisation_id

      scope.none
    end
  end

  private

  def record_or_project
    record.is_a?(Class) ? user&.organisation : record
  end
end
