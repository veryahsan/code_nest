# frozen_string_literal: true

module Sluggable
  extend ActiveSupport::Concern

  SLUG_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  included do
    normalizes :slug, with: ->(slug) { slug.to_s.parameterize }
    validates :slug, presence: true, format: { with: SLUG_PATTERN }
  end
end
