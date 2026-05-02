# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    organisation
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password12345" }
    password_confirmation { "password12345" }
    org_role { :member }

    trait :organisation_admin do
      org_role { :admin }
    end

    trait :super_admin do
      super_admin { true }
      organisation_id { nil }
    end
  end
end
