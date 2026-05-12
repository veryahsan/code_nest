# frozen_string_literal: true

# Updates a Project's mutable attributes. Same slug-uniqueness
# discipline as Teams::UpdateFacade. Language/Technology assignments
# are not handled here — they have their own dedicated controllers in
# Phase C.
module Projects
  class UpdateFacade < ApplicationFacade
    def initialize(project:, attributes:)
      @project = project
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      ActiveRecord::Base.transaction do
        @project.assign_attributes(name: @attributes[:name]) if @attributes.key?(:name)
        @project.assign_attributes(description: @attributes[:description]) if @attributes.key?(:description)
        @project.team_id = resolve_team_id if @attributes.key?(:team_id)

        if @attributes.key?(:slug) && @attributes[:slug].present?
          slug_result = Projects::GenerateUniqueSlugService.call(
            organisation: @project.organisation,
            base_name: @attributes[:slug],
            except_id: @project.id,
          )
          if slug_result.failure?
            @project.errors.add(:slug, slug_result.error)
            raise ActiveRecord::Rollback
          end
          @project.slug = slug_result.value
        end

        unless @project.save
          raise ActiveRecord::Rollback
        end
      end

      return failure(@project) if @project.errors.any?

      success(@project)
    end

    private

    def resolve_team_id
      raw = @attributes[:team_id]
      return nil if raw.blank?

      @project.organisation.teams.where(id: raw).pick(:id)
    end
  end
end
