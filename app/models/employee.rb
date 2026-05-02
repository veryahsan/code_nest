# frozen_string_literal: true

class Employee < ApplicationRecord
  belongs_to :user
  belongs_to :organisation
  belongs_to :manager, class_name: "Employee", inverse_of: :direct_reports, optional: true
  has_many :direct_reports, class_name: "Employee", foreign_key: :manager_id, inverse_of: :manager, dependent: :nullify

  validates :user_id, uniqueness: true

  validate :user_must_not_be_super_admin
  validate :user_must_match_organisation
  validate :manager_must_be_in_same_organisation
  validate :manager_must_not_be_self

  private

  def user_must_not_be_super_admin
    return if user.blank?

    errors.add(:user, "cannot be a platform super admin") if user.super_admin?
  end

  def user_must_match_organisation
    return if user.blank? || organisation.blank?
    return if user.super_admin?

    if user.organisation_id != organisation_id
      errors.add(:organisation, "must match the user's organisation")
    end
  end

  def manager_must_be_in_same_organisation
    return if manager.blank?

    if manager.organisation_id != organisation_id
      errors.add(:manager, "must belong to the same organisation")
    end
  end

  def manager_must_not_be_self
    return if manager_id.blank? || new_record?

    errors.add(:manager, "cannot be the same employee") if manager_id == id
  end
end
