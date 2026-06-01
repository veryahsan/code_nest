# frozen_string_literal: true

# Shared cache store setup for development and production.
# Test uses :null_store directly in config/environments/test.rb.
#
#   REDIS_URL set     -> :redis_cache_store (same Redis as Sidekiq/Cable)
#   REDIS_URL unset   -> :memory_store (development only)
#
module CacheStore
  def self.redis_options
    { url: ENV.fetch("REDIS_URL") }
  end

  def self.apply!(config)
    if ENV["REDIS_URL"].present?
      config.cache_store = :redis_cache_store, redis_options
    else
      config.cache_store = :memory_store
    end
  end

  def self.apply_production!(config)
    config.cache_store = :redis_cache_store, redis_options.merge(
      error_handler: ->(method:, returning:, exception:) {
        Sentry.capture_exception(exception, level: "warning", tags: { method:, returning: }) if defined?(Sentry)
      },
    )
  end
end
