# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable

  belongs_to :organisation, optional: true, inverse_of: :users

  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_one :employee, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id,
                             inverse_of: :invited_by, dependent: :nullify

  enum :org_role, { member: 0, admin: 1 }, prefix: :org

  # Tenant rules:
  # * super admins are platform-wide and must NEVER be tied to an organisation
  # * tenant users may be org-less between confirmation and joining/creating an
  #   organisation, so we don't enforce presence here
  validates :organisation_id, absence: true, if: :super_admin?

  # Platform super admins are provisioned out-of-band (seeds / Active Admin),
  # so they should never be blocked by the email-confirmation gate.
  before_create :auto_confirm_super_admin

  # Devise hook: fires once the email confirmation token is consumed.
  # Business logic lives in Users::PostConfirmationFacade — keep this method
  # a one-line trigger.
  def after_confirmation
    super
    Users::PostConfirmationFacade.call(user: self)
  end

  def organisation_admin?
    org_admin?
  end

  private

  def auto_confirm_super_admin
    skip_confirmation! if super_admin?
  end
end
