# frozen_string_literal: true

class ProjectDocument < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at external_id id project_id title updated_at url]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project]
  end
end
