# frozen_string_literal: true

# Destroys an Organisation. Because `Organisation has_many :users,
# dependent: :restrict_with_error`, we transactionally evict the org's
# users (setting their organisation_id to nil) before calling destroy
# so the lone-admin "shut down my org" flow can complete cleanly.
#
# Refuses if the org still owns teams, projects, employees, or
# invitations — those have their own restrict_with_error semantics and
# must be cleaned up explicitly.
module Organisations
  class DeletionService < ApplicationService
    def initialize(organisation:)
      @organisation = organisation
    end

    def call
      ActiveRecord::Base.transaction do
        @organisation.users.update_all(organisation_id: nil, org_role: User.org_roles[:member])

        unless @organisation.destroy
          raise ActiveRecord::Rollback
        end
      end

      if @organisation.destroyed?
        success(@organisation)
      else
        failure(@organisation.errors.full_messages.to_sentence.presence || "could not delete organisation")
      end
    end
  end
end
