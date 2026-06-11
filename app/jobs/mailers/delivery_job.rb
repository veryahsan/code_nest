# frozen_string_literal: true

# Generic email channel subscriber for the fan-out bus.
#
# Looks the event up in Events::EmailRoutes and enqueues the resulting mailer
# invocation onto the centralized outbox. All email events share this one job —
# the per-event differences (which mailer, recipient, priority, guards) live in
# the route registry, so new events never need a new job class.
module Mailers
  class DeliveryJob < ApplicationJob
    queue_as :mailers

    def perform(event:, **payload)
      spec = Events::EmailRoutes.spec_for(event, **payload)
      return if spec.nil?

      Mailers::Outbox.enqueue(spec[:mailer], spec[:action], *spec[:args], priority: spec[:priority])
    end
  end
end
