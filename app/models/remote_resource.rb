# frozen_string_literal: true

class RemoteResource < ApplicationRecord
  belongs_to :project

  has_encrypted :credentials

  validates :name, presence: true
  validates :kind, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
end
