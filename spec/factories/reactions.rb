# frozen_string_literal: true

FactoryBot.define do
  factory :reaction do
    association :user
    association :reactable, factory: :message
    kind { :like }
  end
end
