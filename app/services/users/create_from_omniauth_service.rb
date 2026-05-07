# frozen_string_literal: true

# Persists a brand-new User and their first Identity from a verified
# OmniAuth payload. Both rows are written inside a single transaction so a
# failure on either side leaves the database untouched.
#
# Two design choices worth flagging:
#
#   * The user is created with `skip_confirmation!`. Both providers we
#     support (Google, GitHub) only return verified email addresses, so a
#     redundant Devise confirmation email would just annoy the user.
#
#   * The password is a Devise-friendly random token — long enough to
#     satisfy `:validatable` on creation but never shown to the user.
#     `User#password_required?` then returns false for any user with at
#     least one identity, so they're never prompted for a password later.
#
# Domain auto-attach and other post-confirmation side-effects are NOT this
# service's concern. The orchestrating facade
# (`Users::OmniauthAuthenticationFacade`) runs `Users::PostConfirmationFacade`
# after a successful create.
module Users
  class CreateFromOmniauthService < ApplicationService
    def initialize(email:, provider:, uid:, raw_info: {})
      @email = email
      @provider = provider
      @uid = uid
      @raw_info = raw_info
    end

    def call
      user = nil
      User.transaction do
        user = User.new(
          email: @email,
          password: Devise.friendly_token[0, 20],
        )
        user.skip_confirmation!
        user.save!
        user.identities.create!(
          provider: @provider,
          uid: @uid,
          email: @email,
          raw_info: @raw_info,
        )
      end

      success(user)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.to_sentence)
    end
  end
end
