# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @organisation = invitation.organisation
    @inviter = invitation.invited_by
    @accept_url = invitation_acceptance_url(@invitation.token)

    mail(
      to: invitation.email,
      subject: "You're invited to join #{@organisation.name} on Code Nest",
    )
  end
end
