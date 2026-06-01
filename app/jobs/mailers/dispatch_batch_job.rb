# frozen_string_literal: true

# Thin scheduler entry point: invoked every 5 seconds by sidekiq-scheduler
# (see config/sidekiq.yml) to drain one batch from the email outbox. All
# logic lives in the service so scheduling stays separate from behaviour.
module Mailers
  class DispatchBatchJob < ApplicationJob
    queue_as :mailers

    def perform
      Mailers::DispatchBatchService.call
    end
  end
end
