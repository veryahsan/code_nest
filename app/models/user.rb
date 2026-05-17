# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github]

  belongs_to :organisation, optional: true, inverse_of: :users

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 80, 80 ]
    attachable.variant :profile, resize_to_limit: [ 200, 200 ]
  end

  validate :acceptable_avatar

  has_many :identities, dependent: :destroy
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_one :employee, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id,
                             inverse_of: :invited_by, dependent: :nullify

  enum :org_role, { member: 0, admin: 1 }, prefix: :org

  attr_accessor :remove_avatar

  # Tenant rules:
  # * super admins are platform-wide and must NEVER be tied to an organisation
  # * tenant users may be org-less between confirmation and joining/creating an
  #   organisation, so we don't enforce presence here
  validates :organisation_id, absence: true, if: :super_admin?

  # Platform super admins are provisioned out-of-band (seeds / Active Admin),
  # so they should never be blocked by the email-confirmation gate.
  before_create :auto_confirm_super_admin

  # Enqueue all Devise notification emails through Active Job so they are
  # processed by a Sidekiq worker instead of blocking the request thread.
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

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

  # A user qualifies as "SSO-only" the moment any identity is linked to
  # them. The flag drives two pieces of UX/policy:
  #   * `password_required?` is relaxed so Devise stops insisting on a
  #     password (the one stored is a random token from
  #     `Users::CreateFromOmniauthService`).
  def sso_only?
    persisted? && identities.exists?
  end

  # See `#sso_only?` — SSO-only users never type a password, so :validatable
  # should not force one on profile edits.
  def password_required?
    return false if sso_only?

    super
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[confirmation_sent_at confirmed_at created_at email id org_role organisation_id
       super_admin updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[employee identities organisation sent_invitations team_memberships teams]
  end

  private

  def auto_confirm_super_admin
    skip_confirmation! if super_admin?
  end

  AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  AVATAR_MAX_SIZE      = 5.megabytes

  def acceptable_avatar
    return unless avatar.attached? && avatar.blob.new_record?

    unless avatar.content_type.in?(AVATAR_CONTENT_TYPES)
      errors.add(:avatar, "must be a JPEG, PNG, or WebP image")
    end

    if avatar.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "must be smaller than 5 MB")
    end
  end
end
