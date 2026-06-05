# frozen_string_literal: true

# Central event bus for domain events.
#
# Maps a named event to one or more subscriber job classes. Each subscriber is
# enqueued independently so failures in one channel (e.g. email) never block
# another (e.g. in-app notification). PublishService itself is synchronous and
# fast — it only enqueues jobs, it never does the work directly.
#
# To add a new subscriber: add its class name to the SUBSCRIBERS hash under the
# relevant event key and implement the job. Jobs follow the same thin-delegate
# pattern as the rest of the app (job → service).
#
# Usage:
#   Events::PublishService.call(event: "user.signed_up", user: user)
#   Events::PublishService.call(event: "message.created", message: message)
module Events
  class PublishService < ApplicationService
    SUBSCRIBERS = {
      "user.signed_up"      => %w[Mailers::WelcomeEmailJob],
      "devise.notification" => %w[Mailers::DeviseNotificationJob],
      "invitation.created"  => %w[Mailers::InvitationEmailJob],
      "message.created"     => %w[Notifications::FanoutJob Mentions::NotifyJob],
    }.freeze

    def initialize(event:, **payload)
      @event   = event
      @payload = payload
    end

    def call
      SUBSCRIBERS.fetch(@event, []).each do |job_class_name|
        job_class_name.constantize.perform_later(**@payload)
      end
      success(nil)
    end
  end
end
