# frozen_string_literal: true

# Delivers a single "message_created" notification to one recipient:
#   1. Upserts the Notification row (find_or_create_by! on the uniqueness key so
#      retries are idempotent).
#   2. Broadcasts the payload to the recipient's NotificationsChannel stream so
#      connected clients update the badge in real time.
#
# Enqueued (one per recipient) by Notifications::FanoutJob. Takes ids rather
# than records so arguments stay small; if either record has since been
# deleted the job no-ops.
module Notifications
  class DeliverJob < ApplicationJob
    queue_as :default

    def perform(message_id:, recipient_id:)
      message   = Message.find_by(id: message_id)
      recipient = User.find_by(id: recipient_id)
      return if message.nil? || recipient.nil?

      notification = Notification.find_or_create_by!(
        recipient:  recipient,
        actor:      message.user,
        notifiable: message,
        kind:       "message_created"
      )

      NotificationsChannel.broadcast_to(recipient, broadcast_payload(notification, message))
    end

    private

    def broadcast_payload(notification, message)
      {
        id:              notification.id,
        kind:            notification.kind,
        read:            notification.read?,
        actor_id:        message.user_id,
        actor_label:     message.sender_label,
        message_id:      message.id,
        conversation_id: message.conversation_id,
        body_preview:    message.body.truncate(120),
        created_at:      notification.created_at.iso8601,
      }
    end
  end
end
