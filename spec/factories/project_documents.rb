# frozen_string_literal: true

FactoryBot.define do
  factory :project_document do
    project
    sequence(:title) { |n| "Document #{n}" }
  end
end
