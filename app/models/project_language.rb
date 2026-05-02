# frozen_string_literal: true

class ProjectLanguage < ApplicationRecord
  belongs_to :project
  belongs_to :language

  validates :language_id, uniqueness: { scope: :project_id }
end
