# frozen_string_literal: true

# Central event bus for domain events.
#
# Maps a named event to one or more generic channel jobs (Mailers::DeliveryJob
# for email, Notifications::DeliveryJob for in-app notifications). Each channel
# is enqueued independently so a failure in one (e.g. email) never blocks
# another (e.g. notification). PublishService itself is synchronous and fast —
# it only enqueues jobs, it never does the work directly.
#
# The per-event *content* (which mailer/recipients/kind) lives in declarative
# route registries (Events::EmailRoutes, Events::NotificationRoutes), so adding
# a new event is a registry entry plus a channel mapping here — no new job
# class. The event name is forwarded to the channel job so it can look up its
# route.
#
# Usage:
#   Events::PublishService.call(event: "user.signed_up", user: user)
#   Events::PublishService.call(event: "message.created", message: message)
module Events
  class PublishService < ApplicationService
    SUBSCRIBERS = {
      "user.signed_up"             => %w[Mailers::DeliveryJob],
      "devise.notification"        => %w[Mailers::DeliveryJob],
      "invitation.created"         => %w[Mailers::DeliveryJob],
      "invitation.accepted"        => %w[Mailers::DeliveryJob Notifications::DeliveryJob],
      "project_membership.created" => %w[Mailers::DeliveryJob Notifications::DeliveryJob],
      "message.created"            => %w[Notifications::DeliveryJob]
    }.freeze

    def initialize(event:, **payload)
      @event   = event
      @payload = payload
    end

    def call
      SUBSCRIBERS.fetch(@event, []).each do |job_class_name|
        job_class_name.constantize.perform_later(event: @event, **@payload)
      end
      success(nil)
    end
  end
end
