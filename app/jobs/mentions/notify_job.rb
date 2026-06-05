# frozen_string_literal: true

# Subscriber for the "message.created" event that handles @mentions.
#
# Mirrors Notifications::FanoutJob, but its recipients are the users explicitly
# mentioned in the message (persisted as MessageMention rows by
# Messages::CreateService) rather than every participant. It enqueues one
# Notifications::DeliverJob per mentioned user with the "user_mentioned" kind,
# which is additive to the generic "message_created" notification.
#
# Recipient ids (not records) are passed so job arguments stay small and a
# since-deleted record simply no-ops on lookup in the deliver job.
module Mentions
  class NotifyJob < ApplicationJob
    queue_as :default

    def perform(message:)
      message.message_mentions.pluck(:mentioned_user_id).each do |recipient_id|
        Notifications::DeliverJob.perform_later(
          message_id:   message.id,
          recipient_id: recipient_id,
          kind:         "user_mentioned"
        )
      end
    end
  end
end
