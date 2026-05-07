# frozen_string_literal: true

FactoryBot.define do
  factory :identity do
    user
    provider { "google_oauth2" }
    sequence(:uid) { |n| "uid-#{n}" }
    sequence(:email) { |n| "identity#{n}@example.com" }
    raw_info { {} }

    trait :github do
      provider { "github" }
    end

    trait :google do
      provider { "google_oauth2" }
    end
  end
end
