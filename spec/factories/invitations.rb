# frozen_string_literal: true

FactoryBot.define do
  factory :invitation do
    organisation
    sequence(:email) { |n| "invite#{n}@example.com" }
    invited_by { association :user, organisation: organisation }
    org_role { :member }
  end
end
