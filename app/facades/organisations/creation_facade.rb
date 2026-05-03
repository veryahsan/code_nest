# frozen_string_literal: true

# Tenant bootstrap flow. Given a free-form name and the user that's creating
# the organisation, this facade:
#   1. derives a unique slug (Organisations::GenerateUniqueSlugService)
#   2. persists the Organisation
#   3. attaches the owner as :admin (Users::AssignToOrganisationService)
#
# Everything happens inside a single transaction, so a failure at any step
# rolls the whole flow back. On success the result value is the persisted
# Organisation. On failure the result error is the (unsaved) Organisation
# carrying validation errors so the caller can re-render its form.
module Organisations
  class CreationFacade < ApplicationFacade
    def initialize(name:, owner:)
      @name = name
      @owner = owner
    end

    def call
      @organisation = Organisation.new(name: @name)

      ActiveRecord::Base.transaction do
        apply_slug || raise(ActiveRecord::Rollback)
        @organisation.save || raise(ActiveRecord::Rollback)
        assign_owner || raise(ActiveRecord::Rollback)
      end

      return failure(@organisation) unless @organisation.persisted? && @organisation.errors.empty?

      success(@organisation)
    end

    private

    def apply_slug
      result = Organisations::GenerateUniqueSlugService.call(base_name: @name)
      if result.failure?
        @organisation.errors.add(:name, result.error)
        return false
      end
      @organisation.slug = result.value
      true
    end

    def assign_owner
      result = Users::AssignToOrganisationService.call(
        user: @owner,
        organisation: @organisation,
        role: :admin,
      )
      return true if result.success?

      @organisation.errors.add(:base, result.error)
      false
    end
  end
end
