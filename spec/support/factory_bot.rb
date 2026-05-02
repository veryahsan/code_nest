# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    begin
      FactoryBot.lint(traits: true)
    rescue FactoryBot::InvalidFactoryError => e
      raise e if ENV["LINT_FACTORIES"] == "true"
    end
  end if ENV["LINT_FACTORIES"] == "true"
end
