# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] ||= "test"

if ENV["COVERAGE"] == "true"
  require "simplecov"
  SimpleCov.start "rails" do
    add_filter "/spec/"
    add_filter "/config/"
  end
end

require_relative "../config/environment"

if ENV["LOCKBOX_MASTER_KEY"].blank?
  ENV["LOCKBOX_MASTER_KEY"] = Lockbox.generate_key
  Lockbox.master_key = ENV["LOCKBOX_MASTER_KEY"]
end

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "capybara/rspec"
require "shoulda/matchers"
require "pundit/matchers"
require "webmock/rspec"
require "vcr"

WebMock.disable_net_connect!(allow_localhost: true)

VCR.configure do |c|
  c.cassette_library_dir = Rails.root.join("spec/cassettes")
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.ignore_localhost = true
end

# Auto-load helpers from spec/support
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include ActionDispatch::TestProcess::FixtureFile

  # Capybara feature spec defaults
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    driven_by :selenium, using: :headless_chrome
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
