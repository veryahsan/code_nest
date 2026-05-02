# frozen_string_literal: true

FactoryBot.define do
  factory :remote_resource do
    project
    sequence(:name) { |n| "API #{n}" }
    kind { "api_key" }
  end
end
