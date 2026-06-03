# frozen_string_literal: true

# Thin override of Devise's registrations controller. Profile settings only
# let users manage their avatar — email and password are not editable here —
# so `#update_resource` always updates without a current-password check.
#
# All other actions (`new`, `create`, `destroy`, …) keep Devise's defaults.
module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_account_update_params, only: :update

    protected

    def update_resource(resource, params)
      purge_avatar_if_requested(resource, params)
      resource.update_without_password(params)
    end

    # The block form *replaces* Devise's default permitted attributes
    # (email, password, …) so profile settings can only touch the avatar.
    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update) do |user_params|
        user_params.permit(:avatar, :remove_avatar)
      end
    end

    private

    def purge_avatar_if_requested(resource, params)
      return unless params.delete(:remove_avatar) == "1"

      resource.avatar.purge
    end
  end
end
