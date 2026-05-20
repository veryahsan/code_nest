# frozen_string_literal: true

FactoryBot.define do
  factory :issue do
    project
    sequence(:summary) { |n| "Issue #{n}" }
  end
end
