source "https://rubygems.org"

ruby "3.4.3"

# ---------------------------------------------------------------------------
# Core framework
# ---------------------------------------------------------------------------
gem "rails", "~> 8.0.5"
gem "sprockets-rails"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "thruster", require: false

# ---------------------------------------------------------------------------
# Database & cache
# ---------------------------------------------------------------------------
gem "pg", "~> 1.5"
gem "redis", "~> 5.3"
gem "connection_pool", "~> 3.0.2"

# ---------------------------------------------------------------------------
# Frontend (Hotwire + Tailwind + Importmap)
# ---------------------------------------------------------------------------
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "dartsass-rails"
gem "image_processing", "~> 1.13"

# ---------------------------------------------------------------------------
# Background jobs (Sidekiq, per stack.md)
# ---------------------------------------------------------------------------
gem "sidekiq", "~> 7.3"

# ---------------------------------------------------------------------------
# Authentication & authorization
# ---------------------------------------------------------------------------
gem "devise", ">= 5.0.3"
gem "omniauth", "~> 2.1"
gem "omniauth-google-oauth2", "~> 1.2"
gem "omniauth-github", "~> 2.0"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "pundit", "~> 2.4"
gem "jwt", "~> 2.9"
gem "bcrypt", "~> 3.1.7"

# ---------------------------------------------------------------------------
# JSON API surface (/api/v1)
# ---------------------------------------------------------------------------
gem "jsonapi-serializer", "~> 2.2"
gem "rack-cors", require: "rack/cors"

# ---------------------------------------------------------------------------
# Pagination
# ---------------------------------------------------------------------------
gem "pagy", "~> 43.5"

# ---------------------------------------------------------------------------
# Encryption helpers
# ---------------------------------------------------------------------------
gem "lockbox", "~> 1.3" # for encrypting RemoteResource credentials beyond Rails' built-in attr_encrypted

# ---------------------------------------------------------------------------
# Observability, audit & analytics
# ---------------------------------------------------------------------------
gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"
gem "lograge"
# Loaded explicitly in Phase 7 once their database stores are migrated.
gem "ahoy_matey", "~> 5.2", require: false
gem "audited", "~> 5.7", require: false

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
gem "dotenv-rails", groups: [ :development, :test ]

# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------
gem "tzinfo-data", platforms: %i[windows jruby]

# ---------------------------------------------------------------------------
# Development & test
# ---------------------------------------------------------------------------
group :development, :test do
  # Pry as the REPL + step-debugger. `pry-rails` makes `bin/rails console`
  # drop into Pry instead of IRB; `pry-byebug` adds `next` / `step` /
  # `continue` / `finish` commands at any `binding.pry` breakpoint.
  gem "pry-rails", "~> 0.3"
  gem "pry-byebug", "~> 3.10"
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.5"
  gem "shoulda-matchers", "~> 6.4"
  gem "rails-controller-testing"
  gem "pundit-matchers", "~> 3.1"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
  gem "annotaterb", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener"
  gem "foreman"
end

# Platform administration (super admins only); organisations are the primary resource.
gem "activeadmin", "~> 3.5"

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "database_cleaner-active_record"
  gem "simplecov", require: false
  gem "webmock"
  gem "vcr"
end
