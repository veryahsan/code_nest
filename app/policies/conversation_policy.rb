# frozen_string_literal: true

class ConversationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user
    return true if user.super_admin?

    record.participant?(user)
  end

  def create?
    user&.organisation_id.present?
  end

  def send_message?
    show?
  end

  # Deleting a group is restricted to its admins (and platform operators).
  # Only standalone groups are manageable here; project channels are removed
  # with their project, and DMs are never deletable.
  def destroy?
    return false unless user

    record.manageable? && (record.admin?(user) || super_admin?)
  end

  # Removing a member is gated by the same admin rule as deleting the group.
  def remove_member?
    destroy?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?
      return scope.none unless user

      scope.for_user(user)
    end
  end
end
