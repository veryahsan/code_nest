# frozen_string_literal: true

# CORS is only needed for the JSON API surface (/api/v1/*) consumed by
# external clients (mobile apps, third-party dashboards). The Hotwire web
# surface is same-origin and does not need CORS.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)

    resource "/api/*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: %w[Authorization X-Request-Id],
             credentials: false,
             max_age: 600
  end
end
