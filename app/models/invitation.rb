# frozen_string_literal: true

class Invitation < ApplicationRecord
  belongs_to :organisation
  belongs_to :invited_by, class_name: "User", inverse_of: :sent_invitations, optional: true

  enum :org_role, { member: 0, admin: 1 }, prefix: :invite

  has_secure_token :token

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  validate :pending_email_unique_within_organisation, on: :create
  validate :inviter_belongs_to_organisation
  validate :expires_at_in_future, on: :create

  scope :pending, -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  def pending?
    accepted_at.nil?
  end

  def accepted?
    accepted_at.present?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[accepted_at created_at email expires_at id invited_by_id org_role organisation_id updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[invited_by organisation]
  end

  private

  def pending_email_unique_within_organisation
    return if organisation.blank? || email.blank?

    scope = organisation.invitations.pending.where.not(id: id)
    errors.add(:email, :taken) if scope.exists?(email: email)
  end

  def inviter_belongs_to_organisation
    return if invited_by.blank? || organisation.blank?
    return if invited_by.super_admin?

    if invited_by.organisation_id != organisation_id
      errors.add(:invited_by, "must belong to the organisation")
    end
  end

  def expires_at_in_future
    return if expires_at.blank?

    errors.add(:expires_at, "must be in the future") if expires_at <= Time.current
  end
end
