# frozen_string_literal: true

# Receives the OAuth redirect coming back from Google or GitHub. The
# controller is intentionally a thin HTTP shell:
#
#   1. Hand the OmniAuth payload to `Users::OmniauthAuthenticationFacade`.
#   2. On success, perform Devise sign-in and redirect.
#   3. On failure, redirect back to /login with a flash.
#
# Per the project convention `controllers call facades, not services`, all
# branching (find / link / create) lives inside the facade.
module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      handle_callback("Google")
    end

    def github
      handle_callback("GitHub")
    end

    # Devise routes here when the OmniAuth strategy itself fails — user
    # cancelled the consent screen, the CSRF token didn't match, the
    # provider returned `invalid_credentials`, etc.
    def failure
      flash[:alert] = "Sign-in with #{failed_strategy_name} was cancelled or failed."
      redirect_to new_user_session_path
    end

    private

    def handle_callback(provider_label)
      result = Users::OmniauthAuthenticationFacade.call(
        auth: request.env["omniauth.auth"],
        current_user: current_user,
      )

      if result.success?
        sign_in_and_redirect(result.value, provider_label)
      else
        flash[:alert] = "#{provider_label} sign-in failed: #{result.error}"
        redirect_to new_user_session_path
      end
    end

    def sign_in_and_redirect(user, provider_label)
      sign_in(user, event: :authentication)
      set_flash_message(:notice, :success, kind: provider_label) if is_navigational_format?
      redirect_to after_sign_in_path_for(user)
    end

    def failed_strategy_name
      failed_strategy&.name.to_s.titleize.presence || "the identity provider"
    end
  end
end
