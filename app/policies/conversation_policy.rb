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

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.super_admin?
      return scope.none unless user

      scope.for_user(user)
    end
  end
end
