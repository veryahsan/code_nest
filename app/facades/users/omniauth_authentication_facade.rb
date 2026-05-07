# frozen_string_literal: true

# Orchestrates the SSO callback flow. Given an OmniAuth payload (and the
# currently signed-in user, if any), the facade resolves it to the User
# the controller should sign in.
#
# Resolution order — first match wins:
#
#   1. An identity already exists for (provider, uid)
#      → `Users::FindByOmniauthIdentityService` returns the user.
#
#   2. `current_user` is signed in (manual "Link my GitHub" from settings)
#      → `Users::LinkOmniauthIdentityService` attaches a new identity to
#        them.
#
#   3. A local user already owns the verified email
#      → `Users::LinkOmniauthIdentityService` attaches a new identity to
#        them, so a password user becomes an SSO user without losing data.
#
#   4. Brand-new visitor
#      → `Users::CreateFromOmniauthService` creates the User + Identity,
#        then `Users::PostConfirmationFacade` runs so SSO sign-ups go
#        through the same domain-auto-attach onboarding as email-confirmed
#        sign-ups (whose `after_confirmation` hook is bypassed by
#        `skip_confirmation!`).
#
# Both providers configured in Devise (Google, GitHub) return only verified
# emails, so trusting `auth.info.email` is safe. If that ever changes, this
# facade is the single place to tighten the check.
module Users
  class OmniauthAuthenticationFacade < ApplicationFacade
    EMAIL_MISSING_ERROR = "the identity provider did not return an email address"

    def initialize(auth:, current_user: nil)
      @auth = auth
      @current_user = current_user
    end

    def call
      return failure(EMAIL_MISSING_ERROR) if email.blank?

      existing_user = Users::FindByOmniauthIdentityService.call(provider: provider, uid: uid).value
      return success(existing_user) if existing_user

      return link_identity_to(@current_user) if @current_user

      local_user = User.find_by(email: email)
      return link_identity_to(local_user) if local_user

      create_user_and_finish_onboarding
    end

    private

    def link_identity_to(user)
      Users::LinkOmniauthIdentityService.call(
        user: user,
        provider: provider,
        uid: uid,
        email: email,
        raw_info: raw_info,
      )
    end

    def create_user_and_finish_onboarding
      creation = Users::CreateFromOmniauthService.call(
        email: email,
        provider: provider,
        uid: uid,
        raw_info: raw_info,
      )
      return creation if creation.failure?

      user = creation.value
      post_confirmation = Users::PostConfirmationFacade.call(user: user)
      return failure(post_confirmation.error) if post_confirmation.failure?

      success(user)
    end

    def email
      @auth.info&.email&.downcase&.strip.presence
    end

    def provider
      @auth.provider
    end

    def uid
      @auth.uid
    end

    def raw_info
      (@auth.extra&.raw_info || {}).to_h
    end
  end
end
