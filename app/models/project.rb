# frozen_string_literal: true

class Project < ApplicationRecord
  include Sluggable

  belongs_to :organisation
  belongs_to :team, optional: true

  has_many :project_languages, dependent: :destroy
  has_many :languages, through: :project_languages
  has_many :project_technologies, dependent: :destroy
  has_many :technologies, through: :project_technologies
  has_many :remote_resources, dependent: :destroy
  has_many :project_documents, dependent: :destroy

  validates :name, presence: true
  validates :slug, uniqueness: { scope: :organisation_id }

  validate :team_must_belong_to_same_organisation

  private

  def team_must_belong_to_same_organisation
    return if team.blank?

    if team.organisation_id != organisation_id
      errors.add(:team, "must belong to the same organisation as the project")
    end
  end
end
