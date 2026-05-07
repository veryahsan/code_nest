# frozen_string_literal: true

# Persists a single Identity row (provider + uid + snapshot email + raw_info)
# against an existing User. This is the *only* allowed way to attach an
# external identity to a user from the application layer — controllers must
# never mutate the `identities` table directly.
#
# Two callers exercise this service:
#   * "Link my GitHub" from account settings (the user is signed in).
#   * The auto-link branch where an OAuth payload's verified email matches
#     a local-password account.
#
# A failure result usually means the (provider, uid) pair is already taken
# by a different user, which the unique index on `identities` enforces.
module Users
  class LinkOmniauthIdentityService < ApplicationService
    LINK_FAILED_ERROR = "could not link identity"

    def initialize(user:, provider:, uid:, email: nil, raw_info: {})
      @user = user
      @provider = provider
      @uid = uid
      @email = email
      @raw_info = raw_info
    end

    def call
      identity = @user.identities.build(
        provider: @provider,
        uid: @uid,
        email: @email,
        raw_info: @raw_info,
      )

      if identity.save
        success(@user)
      else
        failure(identity.errors.full_messages.to_sentence.presence || LINK_FAILED_ERROR)
      end
    end
  end
end
