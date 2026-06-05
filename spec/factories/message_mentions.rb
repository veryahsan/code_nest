# frozen_string_literal: true

FactoryBot.define do
  factory :message_mention do
    message
    mentioned_user { association :user, organisation: message.conversation.organisation }
  end
end
