# frozen_string_literal: true

FactoryBot.define do
  factory :conversation_participant do
    conversation
    user { association :user, organisation: conversation.organisation }
  end
end
