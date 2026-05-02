# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    organisation
    sequence(:name) { |n| "Team #{n}" }
    sequence(:slug) { |n| "team-#{n}" }
  end
end
