# frozen_string_literal: true

return unless ENV["SENTRY_DSN"].present?

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.environment = Rails.env
  config.release = ENV["GIT_COMMIT_SHA"]

  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.1").to_f
  config.profiles_sample_rate = ENV.fetch("SENTRY_PROFILES_SAMPLE_RATE", "0.0").to_f

  config.send_default_pii = false
  config.excluded_exceptions += %w[
    ActionController::RoutingError
    ActiveRecord::RecordNotFound
  ]
end
