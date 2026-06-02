# frozen_string_literal: true

# Drains one batch of buffered email from the priority tiers and sends it
# synchronously, governed by the shared rate limiter.
#
# Per tick:
#   1. Skip entirely while a global backoff is in effect.
#   2. Ask the rate limiter how many sends are allowed right now (budget).
#   3. Allocate that budget across tiers, weighted toward high priority but
#      reserving headroom for lower tiers so they cannot starve.
#   4. Deliver each payload; re-queue transient failures (capped, then
#      dead-lettered). If an entire tick fails, engage a short global backoff
#      so we stop hammering a struggling provider.
module Mailers
  class DispatchBatchService < ApplicationService
    WEIGHTS      = { high: 0.6, default: 0.3, low: 0.1 }.freeze
    PAUSE_KEY    = "mailer:paused_until"

    def initialize(outbox: Outbox.new, rate_limiter: RateLimiter.new,
                   pool: REDIS_POOL, clock: Time)
      @outbox = outbox
      @rate_limiter = rate_limiter
      @pool = pool
      @clock = clock
    end

    def call
      return success(0) if paused?

      budget = @rate_limiter.acquire([ max_per_tick, total_queued ].min)
      return success(0) if budget.zero?

      attempts = 0
      failures = 0

      allocate(budget).each do |tier, count|
        @outbox.pop(tier, count).each do |payload|
          attempts += 1
          failures += 1 unless deliver(payload, tier)
        end
      end

      engage_backoff if attempts.positive? && failures == attempts
      success(attempts - failures)
    end

    private

    def total_queued
      Outbox::PRIORITIES.sum { |tier| @outbox.size(tier) }
    end

    # Two-pass allocation: a weighted reservation first (so lower tiers keep
    # headroom), then any leftover budget cascades down in priority order.
    def allocate(budget)
      sizes = Outbox::PRIORITIES.to_h { |tier| [ tier, @outbox.size(tier) ] }
      alloc = Hash.new(0)
      remaining = budget

      Outbox::PRIORITIES.each do |tier|
        break if remaining <= 0

        want = [ (budget * WEIGHTS[tier]).ceil, sizes[tier], remaining ].min
        alloc[tier] = want
        remaining -= want
      end

      Outbox::PRIORITIES.each do |tier|
        break if remaining <= 0

        extra = [ sizes[tier] - alloc[tier], remaining ].min
        alloc[tier] += extra
        remaining -= extra
      end

      alloc
    end

    def deliver(payload, tier)
      mailer = payload["mailer"].constantize
      args = ActiveJob::Arguments.deserialize(payload["args"])
      mailer.public_send(payload["action"], *args).deliver_now
      true
    rescue ActiveJob::DeserializationError
      # The underlying record is gone; retrying will never succeed, so drop it.
      false
    rescue StandardError => e
      handle_failure(payload, tier, e)
      false
    end

    def handle_failure(payload, tier, error)
      if payload["retries"].to_i < Outbox::MAX_RETRIES
        @outbox.requeue(tier, payload)
      else
        @outbox.dead_letter(payload)
        Sentry.capture_exception(error, tags: { mailer: payload["mailer"] }) if defined?(Sentry)
      end
    end

    def paused?
      raw = @pool.with { |redis| redis.get(PAUSE_KEY) }
      raw.present? && raw.to_f > @clock.now.to_f
    end

    def engage_backoff
      until_ts = @clock.now.to_f + pause_seconds
      @pool.with { |redis| redis.set(PAUSE_KEY, until_ts, ex: pause_seconds + 1) }
    end

    def max_per_tick
      ENV.fetch("MAILER_DISPATCH_MAX", 25).to_i
    end

    def pause_seconds
      ENV.fetch("MAILER_BACKOFF_SECONDS", 30).to_i
    end
  end
end
