# frozen_string_literal: true

# Subscriber for the "devise.notification" event.
# Reconstructs the Devise mailer call and enqueues it onto the centralized
# email outbox at high priority (transactional mail; users wait on it).
#
# `notification` is a string (e.g. "confirmation_instructions") and `args` is
# the array Devise passed alongside it (typically [token, opts]).
module Mailers
  class DeviseNotificationJob < ApplicationJob
    queue_as :mailers

    def perform(user:, notification:, args:)
      Mailers::Outbox.enqueue(
        Devise.mailer,
        notification.to_sym,
        user,
        *args,
        priority: :high
      )
    end
  end
end
