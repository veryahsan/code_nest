# frozen_string_literal: true

FactoryBot.define do
  factory :conversation do
    organisation
    kind { :group }
    sequence(:title) { |n| "Group #{n}" }

    trait :direct do
      kind { :direct }
      title { nil }
    end
  end
end
