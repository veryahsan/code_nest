# frozen_string_literal: true

# Subscriber for the "invitation.created" event.
# Enqueues the invitation email onto the centralized outbox at default priority.
module Mailers
  class InvitationEmailJob < ApplicationJob
    queue_as :mailers

    def perform(invitation:)
      Mailers::Outbox.enqueue(InvitationMailer, :invite, invitation, priority: :default)
    end
  end
end
