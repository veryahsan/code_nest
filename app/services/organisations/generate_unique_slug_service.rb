# frozen_string_literal: true

# Turns a free-form name into a URL-safe organisation slug, appending a numeric
# suffix when the natural slug is already taken. Pure read + string logic;
# performs no writes.
module Organisations
  class GenerateUniqueSlugService < ApplicationService
    BLANK_BASE_ERROR = "could not be derived from the given name"

    def initialize(base_name:)
      @base_name = base_name
    end

    def call
      base = @base_name.to_s.parameterize
      return failure(BLANK_BASE_ERROR) if base.blank?

      success(disambiguate(base))
    end

    private

    def disambiguate(base)
      slug = base
      counter = 0
      while Organisation.exists?(slug: slug)
        counter += 1
        slug = "#{base}-#{counter}"
      end
      slug
    end
  end
end
