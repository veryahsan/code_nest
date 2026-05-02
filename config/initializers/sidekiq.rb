# frozen_string_literal: true

require "sidekiq"

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
redis_config = {
  url: redis_url,
  connect_timeout: ENV.fetch("REDIS_CONNECT_TIMEOUT", 5).to_i,
  read_timeout: ENV.fetch("REDIS_READ_TIMEOUT", 15).to_i,
  write_timeout: ENV.fetch("REDIS_WRITE_TIMEOUT", 5).to_i,
  reconnect_attempts: ENV.fetch("REDIS_RECONNECT_ATTEMPTS", 3).to_i
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
