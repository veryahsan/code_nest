# frozen_string_literal: true

class User < ApplicationRecord
  # Lets any User be embedded in Action Text as an @mention attachment, so a
  # conversation can mention every participant — not only the curated subset
  # that has an Employee (HR) record. Lexxy's @-prompt inserts an
  # <action-text-attachment> carrying this record's signed global id; Action
  # Text resolves it back to the User on render via the `users/_user` partial.
  include ActionText::Attachable

  # Marks the stored attachment so Lexxy's `<lexxy-prompt name="mention">`
  # activates for it and Action Text renders mentions through our partial.
  MENTION_CONTENT_TYPE = "application/vnd.actiontext.mention"

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
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_one :employee, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id,
                             inverse_of: :invited_by, dependent: :nullify
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :messages, dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id, inverse_of: :recipient,
                           dependent: :destroy
  has_many :reactions, dependent: :destroy

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

  # Publish a user.signed_up event the moment a signup is committed so the
  # fan-out bus can fan it out to the welcome email channel (and future ones).
  after_create_commit :enqueue_welcome_email

  # Route Devise notification emails (confirmation, password reset, …) through
  # the fan-out event bus. Mailers::DeliveryJob picks them up (via the
  # devise.notification entry in Events::EmailRoutes) and enqueues them onto the
  # centralized email outbox at high priority.
  def send_devise_notification(notification, *args)
    Events::PublishService.call(
      event:        "devise.notification",
      user:         self,
      notification: notification.to_s,
      args:         args
    )
  end

  # Devise hook: fires once the email confirmation token is consumed.
  # Business logic lives in Users::PostConfirmationFacade — keep this method
  # a one-line trigger.
  def after_confirmation
    super
    Users::PostConfirmationFacade.call(user: self)
  end

  # Content type Action Text stamps on the stored attachment. Must match the
  # `name` on the matching `<lexxy-prompt>` (so "mention" -> this value).
  def content_type
    MENTION_CONTENT_TYPE
  end

  # The @handle shown in the mention pill / prompt. Prefers the Employee handle
  # (curated, org-unique) and otherwise derives a readable one from the email
  # local-part so mentions still work for users without an Employee record.
  def mention_handle
    employee&.handle.presence ||
      Employee.normalize_handle(email.to_s.split("@").first).presence ||
      "user"
  end

  # Human label shown in the prompt menu, mirroring user_avatar_label so the
  # mention UI matches avatars elsewhere.
  def mention_label
    employee&.display_name.presence || email.to_s.split("@").first
  end

  # Plain-text form of a mention. Action Text calls this when flattening a rich
  # body to plain text, keeping previews/search readable as "@handle".
  def attachable_plain_text_representation(_caption = nil)
    "@#{mention_handle}"
  end

  def organisation_admin?
    org_admin?
  end

  # True when the user is the designated lead for the given project.
  def lead_for_project?(project)
    return false if project.blank?

    project_memberships.exists?(project_id: project.id, lead: true)
  end

  # True when the user is a member of the given project.
  def member_of_project?(project)
    return false if project.blank?

    project_memberships.exists?(project_id: project.id)
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
    %w[employee identities organisation projects project_memberships sent_invitations]
  end

  private

  def auto_confirm_super_admin
    skip_confirmation! if super_admin?
  end

  def enqueue_welcome_email
    Events::PublishService.call(event: "user.signed_up", user: self)
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
