# frozen_string_literal: true

# Records and broadcasts a single in-app notification to one recipient:
#   1. Upserts the Notification row (find_or_create_by! on the uniqueness key —
#      recipient + notifiable + kind — so retries are idempotent).
#   2. Broadcasts a generic payload to the recipient's NotificationsChannel
#      stream so connected clients update the badge in real time.
#
# Enqueued (one per recipient) by Notifications::DeliveryJob. Works for any
# notifiable type (Message, Project, Invitation, …); the broadcast preview and
# actor label are derived per type. Takes ids rather than records so arguments
# stay small; if the recipient or notifiable has since been deleted the job
# no-ops. actor_id may be nil for system notifications.
module Notifications
  class RecordJob < ApplicationJob
    queue_as :default

    def perform(recipient_id:, notifiable_type:, notifiable_id:, kind:, actor_id: nil)
      recipient  = User.find_by(id: recipient_id)
      notifiable = notifiable_type.constantize.find_by(id: notifiable_id)
      return if recipient.nil? || notifiable.nil?

      actor = actor_id && User.find_by(id: actor_id)

      notification = Notification.find_or_create_by!(
        recipient:  recipient,
        actor:      actor,
        notifiable: notifiable,
        kind:       kind
      )

      NotificationsChannel.broadcast_to(recipient, broadcast_payload(notification))
    end

    private

    def broadcast_payload(notification)
      {
        id:           notification.id,
        kind:         notification.kind,
        read:         notification.read?,
        actor_id:     notification.actor_id,
        actor_label:  actor_label(notification.actor),
        body_preview: body_preview(notification.notifiable),
        created_at:   notification.created_at.iso8601
      }
    end

    def actor_label(actor)
      actor && Conversation.participant_label(actor)
    end

    def body_preview(notifiable)
      case notifiable
      when Message    then notifiable.body.to_s.truncate(120)
      when Project    then notifiable.name
      when Invitation then notifiable.email
      else ""
      end
    end
  end
end
