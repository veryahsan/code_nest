# frozen_string_literal: true

# Helpers for specs that need the buffered email outbox actually delivered
# (e.g. request specs asserting on ActionMailer::Base.deliveries). Drains the
# outbox the way Mailers::DispatchBatchJob would, looping until nothing more
# is sent.
#
# Since domain events now go through Events::PublishService → subscriber jobs →
# Mailers::Outbox, drain_email_outbox first flushes the ActiveJob queue (the
# subscriber job hop) and then drains the Redis outbox as before.
module EmailOutboxHelpers
  def drain_email_outbox
    perform_enqueued_jobs
    10.times do
      sent = Mailers::DispatchBatchService.call.value.to_i
      break if sent.zero?
    end
  end

  # Discard anything currently buffered (e.g. the welcome + confirmation mail a
  # signup enqueues) so an example can measure only the mail it triggers next.
  def reset_email_outbox
    clear_enqueued_jobs
    REDIS_POOL.with { |redis| redis.flushdb }
  end
end

RSpec.configure do |config|
  config.include ActiveJob::TestHelper
  config.include EmailOutboxHelpers
end
