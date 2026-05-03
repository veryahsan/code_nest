# frozen_string_literal: true

# Side-effects that should run once a user's email has been confirmed.
#
# Today the only side-effect is the email-domain auto-attach: if some
# existing organisation already has a member sharing the new user's email
# domain, the new user is silently joined to that tenant as :member.
#
# The facade is invoked from User#after_confirmation, which is itself a
# one-line trigger so no business logic lives in the model.
module Users
  class PostConfirmationFacade < ApplicationFacade
    def initialize(user:)
      @user = user
    end

    def call
      return success(@user) if skip_auto_attach?

      organisation = Organisations::FindByEmailDomainService.call(email: @user.email).value
      return success(@user) if organisation.nil?

      assignment = Users::AssignToOrganisationService.call(
        user: @user,
        organisation: organisation,
        role: :member,
      )
      return failure(assignment.error) if assignment.failure?

      success(@user)
    end

    private

    def skip_auto_attach?
      @user.super_admin? || @user.organisation_id.present?
    end
  end
end
