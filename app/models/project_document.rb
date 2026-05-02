# frozen_string_literal: true

class ProjectDocument < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
end
