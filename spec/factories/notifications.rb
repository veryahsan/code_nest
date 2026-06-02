# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :recipient, factory: :user
    association :actor,     factory: :user
    association :notifiable, factory: :message
    kind { "message_created" }
    read_at { nil }

    trait :read do
      read_at { 1.hour.ago }
    end
  end
end
