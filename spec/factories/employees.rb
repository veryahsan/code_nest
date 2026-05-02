# frozen_string_literal: true

FactoryBot.define do
  factory :employee do
    organisation

    user { association :user, organisation: organisation }
  end
end
