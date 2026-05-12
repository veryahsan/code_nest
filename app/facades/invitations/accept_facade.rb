# frozen_string_literal: true

# Consumes an invitation token and produces a confirmed, attached
# User. Two flows are supported:
#
#   1. Accept-as-existing-user — when an invitee already has a Code
#      Nest account on the same email, we attach them to the inviting
#      organisation (only allowed if they were org-less).
#   2. Accept-as-new-user — we create a fresh User with the supplied
#      password, mark them confirmed (the email is already proven by
#      the invitation), and attach them.
#
# In both cases we mark the invitation accepted_at and return the
# linked user as the result value.
module Invitations
  class AcceptFacade < ApplicationFacade
    INVALID_ERROR = "invitation token is invalid or expired"
    EMAIL_TAKEN_ERROR = "an account already exists for that email and belongs to a different organisation"

    def initialize(token:, password: nil)
      @token = token
      @password = password
    end

    def call
      invitation = Invitation.find_by(token: @token)
      return failure(INVALID_ERROR) if invitation.nil? || invitation.accepted? || expired?(invitation)

      ActiveRecord::Base.transaction do
        @user = User.find_by(email: invitation.email) || build_new_user(invitation)
        return failure(@user.errors.full_messages.to_sentence) unless @user.persisted? || @user.save

        if @user.organisation_id && @user.organisation_id != invitation.organisation_id
          return failure(EMAIL_TAKEN_ERROR)
        end

        result = Users::AssignToOrganisationService.call(
          user: @user,
          organisation: invitation.organisation,
          role: invitation.org_role.to_sym,
        )
        return failure(result.error) if result.failure?

        invitation.update!(accepted_at: Time.current)
      end

      success(@user)
    end

    private

    def expired?(invitation)
      invitation.expires_at.present? && invitation.expires_at <= Time.current
    end

    def build_new_user(invitation)
      user = User.new(
        email: invitation.email,
        password: @password.to_s,
        password_confirmation: @password.to_s,
      )
      user.skip_confirmation!
      user.save
      user
    end
  end
end
