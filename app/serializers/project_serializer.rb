# frozen_string_literal: true

class ProjectSerializer < ApplicationSerializer
  set_type :project

  attributes :name, :slug, :description, :created_at, :updated_at

  attribute :organisation_id
  attribute :team_id

  attribute :language_ids do |project|
    project.languages.pluck(:id)
  end

  attribute :technology_ids do |project|
    project.technologies.pluck(:id)
  end
end
