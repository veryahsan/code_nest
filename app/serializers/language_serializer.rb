# frozen_string_literal: true

class LanguageSerializer < ApplicationSerializer
  set_type :language

  attributes :name, :code, :created_at, :updated_at
end
