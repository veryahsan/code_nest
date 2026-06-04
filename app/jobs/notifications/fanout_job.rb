# frozen_string_literal: true

# Subscriber for the "message.created" event.
#
# Thin dispatcher: it does no delivery work itself, it only enqueues one
# Notifications::DeliverJob per recipient (every conversation participant
# except the message author). Keeping the unit of work per-recipient means a
# large group never ties up a single worker for the whole fan-out, deliveries
# run in parallel, and a failure for one recipient only retries that recipient.
#
# Recipient ids (not records) are passed so job arguments stay small and a
# since-deleted record simply no-ops on lookup in the deliver job.
module Notifications
  class FanoutJob < ApplicationJob
    queue_as :default

    def perform(message:)
      recipient_ids = message.conversation
                             .participants
                             .where.not(id: message.user_id)
                             .pluck(:id)

      recipient_ids.each do |recipient_id|
        Notifications::DeliverJob.perform_later(
          message_id:   message.id,
          recipient_id: recipient_id
        )
      end
    end
  end
end
