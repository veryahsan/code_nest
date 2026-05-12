# frozen_string_literal: true

class RemoteResourcePolicy < ApplicationPolicy
  include TenantPolicy

  def index?
    member_of_same_org?(record_or_org)
  end

  def show?
    member_of_same_org?(record_or_org)
  end

  def create?
    admin_of_same_org?(record_or_org)
  end

  def update?
    admin_of_same_org?(record_or_org)
  end

  def destroy?
    admin_of_same_org?(record_or_org)
  end

  # Decrypted credentials are only ever shown to org admins (and only
  # when LOCKBOX_MASTER_KEY is configured); regular members see kind +
  # url metadata but never the secret.
  def view_credentials?
    return false if Lockbox.master_key.blank?

    admin_of_same_org?(record_or_org)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?
      return scope.joins(:project).where(projects: { organisation_id: user.organisation_id }) if user&.organisation_id

      scope.none
    end
  end

  private

  def record_or_org
    record.is_a?(Class) ? user&.organisation : record
  end
end
