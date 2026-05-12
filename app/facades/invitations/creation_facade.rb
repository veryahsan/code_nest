# frozen_string_literal: true

# Creates a pending Invitation, sets a default expiry (14 days), and
# enqueues the invite email through ActionMailer's :deliver_later
# (which is routed to Sidekiq's :mailers queue per
# config/application.rb).
module Invitations
  class CreationFacade < ApplicationFacade
    DEFAULT_EXPIRY = 14.days

    def initialize(organisation:, inviter:, attributes:)
      @organisation = organisation
      @inviter = inviter
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      @invitation = @organisation.invitations.new(
        email: @attributes[:email],
        org_role: @attributes[:org_role].presence || :member,
        invited_by: @inviter,
        expires_at: parse_expires_at,
      )

      if @invitation.save
        InvitationMailer.invite(@invitation).deliver_later
        success(@invitation)
      else
        failure(@invitation)
      end
    end

    private

    def parse_expires_at
      raw = @attributes[:expires_at]
      return DEFAULT_EXPIRY.from_now if raw.blank?

      Time.zone.parse(raw.to_s) || DEFAULT_EXPIRY.from_now
    rescue ArgumentError
      DEFAULT_EXPIRY.from_now
    end
  end
end
