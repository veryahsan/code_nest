require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module CodeNest
  class Application < Rails::Application
    config.load_defaults 8.0

    # Autoload `lib/` (excluding non-Ruby subfolders).
    config.autoload_lib(ignore: %w[assets tasks])

    # ---------------------------------------------------------------------
    # Architectural folder layout per architecture_standards.md
    #   app/services/   -> single-purpose service objects
    #   app/facades/    -> orchestrators of multiple services (a complete flow)
    #   app/policies/   -> Pundit authorization policies
    #   app/queries/    -> reusable AR query objects
    #   app/decorators/ -> presentation decorators
    #   app/serializers/-> JSON:API serializers for /api/v1
    #   app/forms/      -> form objects for complex input
    # ---------------------------------------------------------------------
    config.autoload_paths += %W[
      #{config.root}/app/services
      #{config.root}/app/facades
      #{config.root}/app/queries
      #{config.root}/app/decorators
      #{config.root}/app/serializers
      #{config.root}/app/forms
    ]

    # Skip generating system test files; we use Capybara feature specs.
    config.generators.system_tests = nil

    # Background jobs run on Sidekiq (matches stack.md).
    config.active_job.queue_adapter = :sidekiq

    # Route all ActionMailer deliver_later jobs to the dedicated mailers queue
    # so they are processed with the correct priority defined in sidekiq.yml.
    config.action_mailer.deliver_later_queue_name = :mailers

    # Default time zone; can be overridden per organisation later.
    config.time_zone = ENV.fetch("APP_TIME_ZONE", "UTC")

    # Treat /api requests as API-only (no flash, no cookies for sessions).
    config.api_only = false # we keep Hotwire web alongside JSON API
  end
end
