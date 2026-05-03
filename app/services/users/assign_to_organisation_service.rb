# frozen_string_literal: true

# Persists the link between a User and an Organisation, optionally with a
# specific tenant role. Encapsulates the only allowed way to mutate
# `users.organisation_id` / `users.org_role` from the application layer.
module Users
  class AssignToOrganisationService < ApplicationService
    SUPER_ADMIN_ERROR  = "super admins must not belong to a tenant"
    ROLE_INVALID_ERROR = "role must be :member or :admin"

    def initialize(user:, organisation:, role: :member)
      @user = user
      @organisation = organisation
      @role = role.to_sym
    end

    def call
      return failure(SUPER_ADMIN_ERROR) if @user.super_admin?
      return failure(ROLE_INVALID_ERROR) unless User.org_roles.key?(@role.to_s)

      if @user.update(organisation: @organisation, org_role: @role)
        success(@user)
      else
        failure(@user.errors.full_messages.to_sentence.presence || "could not assign organisation")
      end
    end
  end
end
