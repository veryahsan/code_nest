# frozen_string_literal: true

FactoryBot.define do
  factory :project_membership do
    project
    user { association :user, organisation: project.organisation }

    trait :lead do
      lead { true }
    end
  end
end
