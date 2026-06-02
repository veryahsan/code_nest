# frozen_string_literal: true

require "securerandom"

# Shared, provider-wide rate limiter for outbound email.
#
# Implemented as a sliding-window log over a Redis sorted set: each granted
# send records a timestamped member, expired members are trimmed on every
# call, and a request is granted only up to the remaining headroom in the
# current window. Because there is a single drainer today this needs no Lua;
# for multiple concurrent drainers it should be upgraded to an atomic Lua
# token bucket.
module Mailers
  class RateLimiter
    KEY = "mailer:rate"

    def initialize(pool: REDIS_POOL, limit: self.class.default_limit,
                   window: self.class.default_window, clock: Time)
      @pool = pool
      @limit = limit
      @window = window
      @clock = clock
    end

    # Returns how many of the `requested` sends are allowed right now,
    # reserving that many tokens against the current window.
    def acquire(requested)
      requested = requested.to_i
      return 0 if requested <= 0

      now = @clock.now.to_f
      window_start = now - @window

      @pool.with do |redis|
        redis.zremrangebyscore(KEY, 0, window_start)
        current = redis.zcard(KEY)
        granted = [ @limit - current, requested ].min
        granted = 0 if granted.negative?

        granted.times do |i|
          redis.zadd(KEY, now, "#{now}:#{SecureRandom.hex(6)}:#{i}")
        end
        redis.expire(KEY, @window.ceil + 1)
        granted
      end
    end

    def self.default_limit
      ENV.fetch("MAILER_RATE_LIMIT", 25).to_i
    end

    def self.default_window
      ENV.fetch("MAILER_RATE_WINDOW_SECONDS", 1).to_f
    end
  end
end
