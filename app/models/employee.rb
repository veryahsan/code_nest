# frozen_string_literal: true

class Employee < ApplicationRecord
  # Lets an Employee be embedded in Action Text as a mention attachment. Lexxy's
  # @-prompt inserts an <action-text-attachment> carrying this record's signed
  # global id; Action Text resolves it back to the Employee on render and uses
  # the `employees/_employee` partial (see #content_type) to display it.
  include ActionText::Attachable

  # An @mention handle is restricted to this grammar so it has unambiguous
  # boundaries when parsed out of free-text message bodies.
  HANDLE_FORMAT = /\A[a-z0-9_]+\z/
  HANDLE_SUFFIX_LENGTH = 6

  # Marks the stored attachment so Lexxy's `<lexxy-prompt name="mention">`
  # activates for it and Action Text renders mentions through our partial.
  MENTION_CONTENT_TYPE = "application/vnd.actiontext.mention"

  belongs_to :user
  belongs_to :organisation
  belongs_to :manager, class_name: "Employee", inverse_of: :direct_reports, optional: true
  has_many :direct_reports, class_name: "Employee", foreign_key: :manager_id, inverse_of: :manager, dependent: :nullify

  before_validation :assign_handle, on: :create

  validates :user_id, uniqueness: true
  validates :handle, presence: true,
                     uniqueness: { scope: :organisation_id, case_sensitive: false },
                     format: { with: HANDLE_FORMAT },
                     length: { in: 2..40 }

  validate :user_must_not_be_super_admin
  validate :user_must_match_organisation
  validate :manager_must_be_in_same_organisation
  validate :manager_must_not_be_self

  # Canonicalises any seed string into the handle grammar (lowercase, only
  # [a-z0-9_], no leading/trailing/repeated underscores).
  def self.normalize_handle(raw)
    raw.to_s.downcase.gsub(/[^a-z0-9_]+/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "")
  end

  # Returns a handle that is unique within the organisation. The base (an email
  # local-part) is used as-is when free; otherwise a short random suffix is
  # appended until an opening is found. The DB unique index is the real guard;
  # this just finds a likely-free candidate.
  def self.generate_handle(base, organisation_id)
    base = normalize_handle(base).presence || "user"
    return base unless exists?(organisation_id: organisation_id, handle: base)

    loop do
      candidate = "#{base}_#{SecureRandom.alphanumeric(HANDLE_SUFFIX_LENGTH).downcase}"
      return candidate unless exists?(organisation_id: organisation_id, handle: candidate)
    end
  end

  # Content type Action Text stamps on the stored attachment. Must match the
  # `name` on the matching `<lexxy-prompt>` (so "mention" -> this value).
  def content_type
    MENTION_CONTENT_TYPE
  end

  # Display name shown in the mention pill / prompt menu, with a sensible
  # fallback so a blank profile still renders something meaningful.
  def mention_label
    display_name.presence || handle
  end

  # Plain-text form of a mention. Action Text calls this when flattening a rich
  # body to plain text (Message#body), keeping previews/search readable as
  # "@handle" rather than an empty attachment placeholder.
  def attachable_plain_text_representation(_caption = nil)
    "@#{handle}"
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at display_name handle id job_title manager_id organisation_id updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[direct_reports manager organisation user]
  end

  private

  def assign_handle
    return if handle.present?

    self.handle = self.class.generate_handle(user&.email.to_s.split("@").first, organisation_id)
  end

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
