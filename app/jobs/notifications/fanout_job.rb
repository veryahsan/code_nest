# frozen_string_literal: true

# Subscriber for the "message.created" event.
# For each conversation participant (excluding the message author):
#   1. Upserts a Notification row (find_or_create_by! on the uniqueness key so
#      retries are idempotent).
#   2. Broadcasts the notification payload to the recipient's
#      NotificationsChannel stream so connected clients update in real time.
#
# Runs on the :critical queue so a slow email provider can never delay
# in-app badge delivery.
module Notifications
  class FanoutJob < ApplicationJob
    queue_as :critical

    def perform(message:)
      recipients = message.conversation.participants.where.not(id: message.user_id)

      recipients.each do |recipient|
        notification = Notification.find_or_create_by!(
          recipient:  recipient,
          actor:      message.user,
          notifiable: message,
          kind:       "message_created"
        )

        NotificationsChannel.broadcast_to(recipient, broadcast_payload(notification, message))
      end
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
