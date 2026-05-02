# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  protected

  # Platform operator (your company); not tied to a customer organisation.
  def super_admin?
    user&.super_admin?
  end

  # Admin role within the customer's organisation (one org per user).
  def organisation_admin?(organisation = nil)
    return false unless user

    org = organisation || user.organisation
    return false unless org && user.organisation_id == org.id

    user.org_admin?
  end

  def super_admin_or_organisation_admin?(organisation = nil)
    super_admin? || organisation_admin?(organisation)
  end
end
