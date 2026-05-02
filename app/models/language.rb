# frozen_string_literal: true

class Language < ApplicationRecord
  CODE_PATTERN = /\A[a-z][a-z0-9_-]*\z/

  has_many :project_languages, dependent: :restrict_with_error
  has_many :projects, through: :project_languages

  normalizes :code, with: ->(code) { code.to_s.downcase.strip }
  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, format: { with: CODE_PATTERN }
end
