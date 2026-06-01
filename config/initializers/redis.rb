# frozen_string_literal: true

# Shared Redis connection pool for application-level Redis usage
# (e.g. the centralized email outbox in Mailers::Outbox and the
# Mailers::RateLimiter).
#
# This is intentionally separate from Sidekiq's own pool (configured in
# config/initializers/sidekiq.rb) so that buffering business data does not
# contend with Sidekiq's job-processing connections. Both point at the same
# server via REDIS_URL, falling back to the local default used elsewhere.
require "redis"
require "connection_pool"

REDIS_POOL =
  if Rails.env.test?
    # The test suite uses one shared in-memory MockRedis so specs exercising
    # the email outbox and rate limiter get real list/sorted-set semantics
    # without a running Redis server. A single instance (pool size 1) is used
    # because separate MockRedis instances do not share data.
    require "mock_redis"
    shared = MockRedis.new
    ConnectionPool.new(size: 1, timeout: 5) { shared }
  else
    ConnectionPool.new(
      size: ENV.fetch("REDIS_POOL_SIZE", 5).to_i,
      timeout: ENV.fetch("REDIS_POOL_TIMEOUT", 5).to_i,
    ) { Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")) }
  end
