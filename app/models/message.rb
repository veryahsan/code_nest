# frozen_string_literal: true

# A single chat message inside a conversation. On commit it is pushed to
# every subscriber of the conversation's Action Cable stream.
class Message < ApplicationRecord
  include Reactable

  MAX_LENGTH = 5_000

  belongs_to :conversation
  belongs_to :user

  has_many :message_mentions, dependent: :destroy
  has_many :mentioned_users, through: :message_mentions, source: :mentioned_user

  validates :body, presence: true, length: { maximum: MAX_LENGTH }

  after_create_commit :broadcast_to_conversation
  after_create_commit :publish_message_event

  scope :chronological, -> { order(:created_at) }

  def sender_label
    Conversation.participant_label(user)
  end

  # True when the message carries sanitized rich HTML to render instead of the
  # plain text body.
  def rich?
    body_html.present?
  end

  def broadcast_payload
    {
      id: id,
      conversation_id: conversation_id,
      user_id: user_id,
      sender_label: sender_label,
      body: body,
      body_html: body_html,
      created_at: created_at.iso8601
    }
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[body conversation_id created_at id updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[conversation user]
  end

  private

  def broadcast_to_conversation
    ConversationChannel.broadcast_to(conversation, message: broadcast_payload)
  end

  def publish_message_event
    Events::PublishService.call(event: "message.created", message: self)
  end
end
