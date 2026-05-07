# frozen_string_literal: true

# Looks up a User by an OmniAuth identity tuple (provider + uid).
#
# This is the cheapest, most authoritative way to recognise a returning SSO
# user — every (provider, uid) is guaranteed unique by the database index on
# `identities`. The service never raises, never writes, and always succeeds:
# the result value is the User on hit, `nil` on miss. Deciding what to do
# with a miss (link to current_user, link by email, create a new user) is
# the orchestrator's job, not ours.
module Users
  class FindByOmniauthIdentityService < ApplicationService
    def initialize(provider:, uid:)
      @provider = provider
      @uid = uid
    end

    def call
      identity = Identity.find_by(provider: @provider, uid: @uid)
      success(identity&.user)
    end
  end
end
