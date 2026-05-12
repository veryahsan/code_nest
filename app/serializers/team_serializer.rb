# frozen_string_literal: true

class TeamSerializer < ApplicationSerializer
  set_type :team

  attributes :name, :slug, :created_at, :updated_at

  attribute :organisation_id do |team|
    team.organisation_id
  end
end
