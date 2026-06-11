# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :user
    association :commentable, factory: :issue
    body { "A comment" }
  end
end
