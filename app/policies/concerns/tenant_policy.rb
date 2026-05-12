# frozen_string_literal: true

# Mixed into every Pundit policy that operates on a tenant-owned record.
# Centralises the "does this record belong to the user's organisation?"
# check so individual policies stay small.
module TenantPolicy
  extend ActiveSupport::Concern

  protected

  # True when the supplied record (or the policy's own #record) belongs to
  # the current user's organisation. Super admins always pass.
  def same_org?(target = record)
    return false unless user
    return true if user.super_admin?
    return false unless user.organisation_id

    org_id = extract_organisation_id(target)
    return false if org_id.nil?

    user.organisation_id == org_id
  end

  def member_of_same_org?(target = record)
    return true if user&.super_admin?
    return false unless user&.organisation_id

    same_org?(target)
  end

  def admin_of_same_org?(target = record)
    return false unless user
    return true if user.super_admin?
    return false unless user.org_admin?

    same_org?(target)
  end

  private

  def extract_organisation_id(target)
    return target.id if target.is_a?(Organisation)
    return target.organisation_id if target.respond_to?(:organisation_id) && target.organisation_id
    return target.organisation.id if target.respond_to?(:organisation) && target.organisation
    return target.project.organisation_id if target.respond_to?(:project) && target.project
    return target.team.organisation_id if target.respond_to?(:team) && target.team

    nil
  end
end
