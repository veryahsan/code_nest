# frozen_string_literal: true

# Subscriber for the "user.signed_up" event.
# Enqueues the welcome email onto the centralized outbox at low priority.
#
# Super admins are provisioned out-of-band (seeds / Active Admin) and never
# receive the welcome email.
module Mailers
  class WelcomeEmailJob < ApplicationJob
    queue_as :mailers

    def perform(user:)
      return if user.super_admin?

      Mailers::Outbox.enqueue(WelcomeMailer, :welcome, user, priority: :low)
    end
  end
end
