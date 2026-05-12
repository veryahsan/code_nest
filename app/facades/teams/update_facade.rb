# frozen_string_literal: true

# Updates a Team's name and/or slug. When the slug is touched it is
# re-normalised + uniqueness-checked through the slug service so the
# DB-level unique index never trips.
module Teams
  class UpdateFacade < ApplicationFacade
    def initialize(team:, attributes:)
      @team = team
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      ActiveRecord::Base.transaction do
        @team.assign_attributes(name: @attributes[:name]) if @attributes.key?(:name)

        if @attributes.key?(:slug) && @attributes[:slug].present?
          slug_result = Teams::GenerateUniqueSlugService.call(
            organisation: @team.organisation,
            base_name: @attributes[:slug],
            except_id: @team.id,
          )
          if slug_result.failure?
            @team.errors.add(:slug, slug_result.error)
            raise ActiveRecord::Rollback
          end
          @team.slug = slug_result.value
        end

        unless @team.save
          raise ActiveRecord::Rollback
        end
      end

      return failure(@team) if @team.errors.any?

      success(@team)
    end
  end
end
