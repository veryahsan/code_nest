# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    organisation
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password12345" }
    password_confirmation { "password12345" }
    org_role { :member }
    # Default users are pre-confirmed so existing specs don't have to deal with
    # the email-confirmation gate. Use the `:unconfirmed` trait when testing
    # the confirmable flow itself.
    confirmed_at { Time.current }

    trait :organisation_admin do
      org_role { :admin }
    end

    trait :super_admin do
      super_admin { true }
      organisation_id { nil }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    # For specs that exercise the post-confirmation onboarding state.
    trait :without_organisation do
      organisation { nil }
    end
  end
end
