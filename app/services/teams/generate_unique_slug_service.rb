# frozen_string_literal: true

# Mirrors Organisations::GenerateUniqueSlugService but disambiguates
# inside a single organisation (Team slugs are unique per organisation,
# not globally — see the Sluggable concern + the
# index_teams_on_organisation_id_and_slug index).
module Teams
  class GenerateUniqueSlugService < ApplicationService
    BLANK_BASE_ERROR = "could not be derived from the given name"

    def initialize(organisation:, base_name:, except_id: nil)
      @organisation = organisation
      @base_name = base_name
      @except_id = except_id
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
      while exists?(slug)
        counter += 1
        slug = "#{base}-#{counter}"
      end
      slug
    end

    def exists?(slug)
      scope = @organisation.teams.where(slug: slug)
      scope = scope.where.not(id: @except_id) if @except_id
      scope.exists?
    end
  end
end
