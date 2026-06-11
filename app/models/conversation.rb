# frozen_string_literal: true

# A conversation is either a 1:1 direct message or a group chat. Group
# chats are capped at GROUP_CAPACITY participants. A group may optionally
# be owned by a Project (its auto-created channel), in which case its
# roster mirrors the project's membership.
class Conversation < ApplicationRecord
  GROUP_CAPACITY = ProjectMembership::GROUP_CAPACITY

  belongs_to :organisation
  belongs_to :project, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  # `scopes: false` because a `group` scope would clash with
  # ActiveRecord::Calculations#group. Predicates (#direct?, #group?) and
  # setters are still generated.
  enum :kind, { direct: 0, group: 1 }, scopes: false

  validates :title, presence: true, if: :group?
  validate :direct_conversations_are_not_project_owned

  scope :for_user, ->(user) {
    joins(:conversation_participants).where(conversation_participants: { user_id: user.id })
  }

  # Display label, resolved from the other participant for DMs.
  def display_title(viewer = nil)
    return title if group?

    other = viewer ? participants.where.not(id: viewer.id).first : participants.first
    other ? Conversation.participant_label(other) : "Direct message"
  end

  def self.participant_label(user)
    user.employee&.display_name.presence || user.email.to_s.split("@").first
  end

  def participant?(user)
    return false if user.blank?

    conversation_participants.exists?(user_id: user.id)
  end

  # Group admins can manage the group (remove members, delete it). The
  # creator is seeded as admin; the flag lives on conversation_participants.
  def admin?(user)
    return false if user.blank?

    conversation_participants.exists?(user_id: user.id, admin: true)
  end

  # Whether this conversation can be managed from the messaging UI. Only
  # standalone groups qualify: project channels are driven by the project's
  # roster and are removed when the project is deleted, and DMs have no admin.
  def manageable?
    group? && project_id.nil?
  end

  def add_participant(user)
    return if user.blank?

    conversation_participants.find_or_create_by!(user: user)
  end

  def remove_participant(user)
    return if user.blank?

    conversation_participants.where(user: user).destroy_all
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at created_by_id id kind organisation_id project_id title updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[conversation_participants created_by messages organisation participants project]
  end

  private

  def direct_conversations_are_not_project_owned
    errors.add(:project, "cannot be set on a direct conversation") if direct? && project_id.present?
  end
end
