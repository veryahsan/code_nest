# frozen_string_literal: true

# Generic in-app notification dispatcher for the fan-out bus.
#
# Thin: it does no delivery work itself. It looks the event up in
# Events::NotificationRoutes and, for every resulting delivery, enqueues one
# Notifications::RecordJob per recipient. Keeping the unit of work per-recipient
# means a large audience never ties up a single worker for the whole fan-out,
# deliveries run in parallel, and a failure for one recipient only retries that
# recipient. All notification events share this one job — the per-event
# recipients/actor/kind live in the route registry.
#
# Recipient and notifiable ids (not records) are passed downstream so job
# arguments stay small and a since-deleted record simply no-ops on lookup.
module Notifications
  class DeliveryJob < ApplicationJob
    queue_as :default

    def perform(event:, **payload)
      Events::NotificationRoutes.deliveries_for(event, **payload).each do |delivery|
        notifiable = delivery[:notifiable]
        next if notifiable.nil?

        Array(delivery[:recipient_ids]).each do |recipient_id|
          Notifications::RecordJob.perform_later(
            recipient_id:    recipient_id,
            actor_id:        delivery[:actor_id],
            notifiable_type: notifiable.class.name,
            notifiable_id:   notifiable.id,
            kind:            delivery[:kind]
          )
        end
      end
    end
  end
end
