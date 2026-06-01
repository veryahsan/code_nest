# frozen_string_literal: true

# Centralized, Redis-backed buffer for all outbound application email.
#
# Producers enqueue a mailer invocation onto one of three priority tiers
# (high / default / low); a single scheduled drainer (Mailers::DispatchBatchJob)
# pops from these lists behind a shared rate limiter and sends synchronously.
# This decouples delivery from the shared email provider's availability and
# lets us respect its global rate limit regardless of how many call sites
# enqueue mail.
#
# Payload shape (JSON):
#   { "mailer" => "WelcomeMailer", "action" => "welcome",
#     "args" => <ActiveJob::Arguments.serialize(...)>, "retries" => 0 }
#
# Args are serialized exactly like ActionMailer::MailDeliveryJob, so
# ActiveRecord arguments round-trip through GlobalID.
module Mailers
  class Outbox
    PRIORITIES  = %i[high default low].freeze
    MAX_RETRIES = 5
    KEY_PREFIX  = "mailer:outbox"
    DEAD_KEY    = "#{KEY_PREFIX}:dead".freeze

    class << self
      def enqueue(mailer, action, *args, priority: :default)
        new.enqueue(mailer, action, *args, priority: priority)
      end
    end

    def initialize(pool: REDIS_POOL)
      @pool = pool
    end

    # Append a mailer invocation to the tail of the given priority tier.
    def enqueue(mailer, action, *args, priority: :default)
      payload = {
        "mailer"  => mailer.to_s,
        "action"  => action.to_s,
        "args"    => ActiveJob::Arguments.serialize(args),
        "retries" => 0
      }
      @pool.with { |redis| redis.rpush(key(normalize(priority)), JSON.generate(payload)) }
    end

    # Pop up to `count` payloads (FIFO) off the head of a tier.
    def pop(tier, count)
      return [] if count.to_i <= 0

      raw = @pool.with { |redis| redis.lpop(key(normalize(tier)), count.to_i) }
      Array(raw).filter_map { |item| parse(item) }
    end

    # Re-enqueue a payload at the tail of its tier with a bumped retry counter
    # so a poison message cannot block the rest of the batch.
    def requeue(tier, payload)
      entry = payload.merge("retries" => payload["retries"].to_i + 1)
      @pool.with { |redis| redis.rpush(key(normalize(tier)), JSON.generate(entry)) }
    end

    # Park a payload that has exhausted its retries for later inspection.
    def dead_letter(payload)
      @pool.with { |redis| redis.rpush(DEAD_KEY, JSON.generate(payload)) }
    end

    def size(tier)
      @pool.with { |redis| redis.llen(key(normalize(tier))) }
    end

    private

    def normalize(priority)
      tier = priority.to_sym
      PRIORITIES.include?(tier) ? tier : :default
    end

    def key(tier)
      "#{KEY_PREFIX}:#{tier}"
    end

    def parse(item)
      JSON.parse(item)
    rescue JSON::ParserError
      nil
    end
  end
end
