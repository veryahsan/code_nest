# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    organisation
    sequence(:name) { |n| "Project #{n}" }
    sequence(:slug) { |n| "project-#{n}" }
  end
end
