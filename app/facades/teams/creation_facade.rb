# frozen_string_literal: true

# Creates a Team scoped to the given organisation. Derives a unique
# per-org slug via Teams::GenerateUniqueSlugService and persists the
# record. Returns the persisted Team on success, or the unsaved Team
# carrying validation errors on failure.
module Teams
  class CreationFacade < ApplicationFacade
    def initialize(organisation:, attributes:)
      @organisation = organisation
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      @team = @organisation.teams.new(name: @attributes[:name])

      ActiveRecord::Base.transaction do
        apply_slug || raise(ActiveRecord::Rollback)
        @team.save || raise(ActiveRecord::Rollback)
      end

      return failure(@team) unless @team.persisted? && @team.errors.empty?

      success(@team)
    end

    private

    def apply_slug
      base = @attributes[:slug].presence || @team.name
      result = Teams::GenerateUniqueSlugService.call(organisation: @organisation, base_name: base)
      if result.failure?
        @team.errors.add(:name, result.error)
        return false
      end
      @team.slug = result.value
      true
    end
  end
end
