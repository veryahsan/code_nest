# frozen_string_literal: true

FactoryBot.define do
  factory :language do
    sequence(:name) { |n| "Language #{n}" }
    sequence(:code) { |n| "lang#{n}" }
  end
end
