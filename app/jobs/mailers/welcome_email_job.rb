# frozen_string_literal: true

# Subscriber for the "user.signed_up" event.
# Delegates to Mailers::EnqueueWelcomeEmailService which owns the super-admin
# skip logic and the actual Outbox enqueue call.
module Mailers
  class WelcomeEmailJob < ApplicationJob
    queue_as :mailers

    def perform(user:)
      Mailers::EnqueueWelcomeEmailService.call(user: user)
    end
  end
end
