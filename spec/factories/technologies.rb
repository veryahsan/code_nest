# frozen_string_literal: true

FactoryBot.define do
  factory :technology do
    sequence(:name) { |n| "Technology #{n}" }
    sequence(:slug) { |n| "tech-#{n}" }
  end
end
