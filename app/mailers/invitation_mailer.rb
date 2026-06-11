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

  # Sent to the inviter once their invitee accepts. Only invoked when an inviter
  # is present (see Events::EmailRoutes).
  def accepted(invitation)
    @invitation     = invitation
    @organisation   = invitation.organisation
    @inviter        = invitation.invited_by
    @accepted_email = invitation.email
    @members_url    = invitations_url

    mail(
      to: @inviter.email,
      subject: "#{@accepted_email} accepted your invitation to #{@organisation.name}",
    )
  end
end
