# frozen_string_literal: true

class Language < ApplicationRecord
  CODE_PATTERN = /\A[a-z][a-z0-9_-]*\z/

  has_many :project_languages, dependent: :restrict_with_error
  has_many :projects, through: :project_languages

  normalizes :code, with: ->(code) { code.to_s.downcase.strip }
  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, format: { with: CODE_PATTERN }

  def self.ransackable_attributes(_auth_object = nil)
    %w[code created_at id name updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project_languages projects]
  end
end
