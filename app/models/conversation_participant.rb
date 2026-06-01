# frozen_string_literal: true

# Membership of a User in a Conversation. Enforces conversation capacity:
# two for direct messages, GROUP_CAPACITY for groups.
class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates :user_id, uniqueness: { scope: :conversation_id }
  validate :within_capacity, on: :create

  def mark_read!
    update_column(:last_read_at, Time.current)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[conversation_id created_at id last_read_at updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[conversation user]
  end

  private

  def within_capacity
    return if conversation.blank?

    current = conversation.conversation_participants.where.not(id: id).count

    if conversation.direct? && current >= 2
      errors.add(:base, "direct conversations allow only two participants")
    elsif conversation.group? && current >= Conversation::GROUP_CAPACITY
      errors.add(:base, "groups are limited to #{Conversation::GROUP_CAPACITY} members")
    end
  end
end
