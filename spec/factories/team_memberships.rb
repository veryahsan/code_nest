# frozen_string_literal: true

FactoryBot.define do
  factory :team_membership do
    team
    user { association :user, organisation: team.organisation }
  end
end
