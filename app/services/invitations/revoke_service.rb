# frozen_string_literal: true

# Hard-deletes a pending Invitation. Already-accepted invitations are
# preserved as audit history.
module Invitations
  class RevokeService < ApplicationService
    def initialize(invitation:)
      @invitation = invitation
    end

    def call
      return failure("invitation already accepted") if @invitation.accepted?

      if @invitation.destroy
        success(@invitation)
      else
        failure(@invitation.errors.full_messages.to_sentence.presence || "could not revoke invitation")
      end
    end
  end
end
