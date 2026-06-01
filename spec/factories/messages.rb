# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    conversation
    user { association :user, organisation: conversation.organisation }
    body { "Hello there" }
  end
end
