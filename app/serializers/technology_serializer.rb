# frozen_string_literal: true

class TechnologySerializer < ApplicationSerializer
  set_type :technology

  attributes :name, :slug, :created_at, :updated_at
end
