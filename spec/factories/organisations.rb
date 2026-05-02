# frozen_string_literal: true

FactoryBot.define do
  factory :organisation do
    sequence(:name) { |n| "Organisation #{n}" }
    sequence(:slug) { |n| "org-#{n}" }
  end
end
