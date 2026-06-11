# frozen_string_literal: true

# A single chat message inside a conversation. On commit it is pushed to
# every subscriber of the conversation's Action Cable stream.
class Message < ApplicationRecord
  include Reactable

  MAX_LENGTH = 5_000

  belongs_to :conversation
  belongs_to :user

  # Rich body authored in the Lexxy editor. Mentions live here as Action Text
  # attachments (signed global ids), and `body` is kept as the derived plain
  # text for search, previews and the no-rich-text path.
  has_rich_text :body_text

  has_many :message_mentions, dependent: :destroy
  has_many :mentioned_users, through: :message_mentions, source: :mentioned_user

  validates :body, presence: true, length: { maximum: MAX_LENGTH }

  after_create_commit :broadcast_to_conversation
  after_create_commit :publish_message_event

  scope :chronological, -> { order(:created_at) }

  def sender_label
    Conversation.participant_label(user)
  end

  # True when the message carries rich body content (formatting and/or mentions)
  # that should render instead of the plain text body.
  def rich?
    body_text.body.present?
  end

  # Action Text body rendered to its canonical HTML, with mention attachments
  # resolved to the employees/_employee partial. Rendered server-side so signed
  # global ids resolve (the client never sees raw <action-text-attachment>).
  # Returns nil for plain-text-only messages so callers fall back to `body`.
  def rendered_body_html
    return nil unless rich?

    with_url_host do
      ApplicationController.render(
        partial: "conversations/message_body",
        locals: { message: self }
      )
    end
  end

  def broadcast_payload
    {
      id: id,
      conversation_id: conversation_id,
      user_id: user_id,
      sender_label: sender_label,
      body: body,
      body_html: rendered_body_html,
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

  # Broadcasts render in an after_create_commit callback with no HTTP request, so
  # URL helpers have no host and Active Storage image links fall back to the
  # "example.org" placeholder (images 404 until reload). Lend the router the host
  # the app already configures for mailer links, just for the render.
  def with_url_host
    routes = Rails.application.routes
    previous = routes.default_url_options
    routes.default_url_options = previous.merge(Rails.application.config.action_mailer.default_url_options || {})
    yield
  ensure
    routes.default_url_options = previous
  end

  def broadcast_to_conversation
    ConversationChannel.broadcast_to(conversation, message: broadcast_payload)
  end

  def publish_message_event
    Events::PublishService.call(event: "message.created", message: self)
  end
end
