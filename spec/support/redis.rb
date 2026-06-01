# frozen_string_literal: true

# The test environment backs REDIS_POOL with a single in-memory MockRedis
# (see config/initializers/redis.rb). Unlike the database, it is not wrapped
# in a transaction, so flush it before each example to keep the email outbox
# and rate-limiter state isolated.
RSpec.configure do |config|
  config.before do
    REDIS_POOL.with { |redis| redis.flushdb }
  end
end
