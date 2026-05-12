# frozen_string_literal: true

class OrganisationSerializer < ApplicationSerializer
  set_type :organisation

  attributes :name, :slug, :created_at, :updated_at
end
