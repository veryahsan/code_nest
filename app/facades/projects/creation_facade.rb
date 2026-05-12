# frozen_string_literal: true

# Creates a Project inside an organisation. Mirrors the Project
# creation flow described in the project's architecture standards
# (see ProjectCreationFacade in README): one transaction, slug derived
# via Projects::GenerateUniqueSlugService, optional team assignment,
# bulk attachment of Languages and Technologies.
module Projects
  class CreationFacade < ApplicationFacade
    def initialize(organisation:, attributes:)
      @organisation = organisation
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      @project = @organisation.projects.new(
        name: @attributes[:name],
        description: @attributes[:description],
        team_id: resolve_team_id,
      )

      ActiveRecord::Base.transaction do
        apply_slug || raise(ActiveRecord::Rollback)
        @project.save || raise(ActiveRecord::Rollback)
        attach_languages || raise(ActiveRecord::Rollback)
        attach_technologies || raise(ActiveRecord::Rollback)
      end

      return failure(@project) unless @project.persisted? && @project.errors.empty?

      success(@project)
    end

    private

    def resolve_team_id
      raw = @attributes[:team_id]
      return nil if raw.blank?

      @organisation.teams.where(id: raw).pick(:id)
    end

    def apply_slug
      base = @attributes[:slug].presence || @project.name
      result = Projects::GenerateUniqueSlugService.call(organisation: @organisation, base_name: base)
      if result.failure?
        @project.errors.add(:name, result.error)
        return false
      end
      @project.slug = result.value
      true
    end

    def attach_languages
      ids = Array(@attributes[:language_ids]).reject(&:blank?).map(&:to_i)
      return true if ids.empty?

      ids.each do |lid|
        next unless Language.exists?(id: lid)

        @project.project_languages.create!(language_id: lid)
      end
      true
    rescue ActiveRecord::RecordInvalid => e
      @project.errors.add(:base, e.message)
      false
    end

    def attach_technologies
      ids = Array(@attributes[:technology_ids]).reject(&:blank?).map(&:to_i)
      return true if ids.empty?

      ids.each do |tid|
        next unless Technology.exists?(id: tid)

        @project.project_technologies.create!(technology_id: tid)
      end
      true
    rescue ActiveRecord::RecordInvalid => e
      @project.errors.add(:base, e.message)
      false
    end
  end
end
