# frozen_string_literal: true

# Thin override of Devise's registrations controller. The only thing it
# customises is `#update_resource` so that SSO-only users — who do not
# have a usable password to "confirm with" — can still edit their email
# from `/edit` without being blocked by `update_with_password`.
#
# All other actions (`new`, `create`, `destroy`, …) keep Devise's
# defaults: local-password sign-ups still hit the validatable path and
# still need their current password to authorise destructive changes.
module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_account_update_params, only: :update

    protected

    def update_resource(resource, params)
      purge_avatar_if_requested(resource, params)
      return resource.update_without_password(params) if resource.sso_only?

      super
    end

    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: [ :avatar, :remove_avatar ])
    end

    private

    def purge_avatar_if_requested(resource, params)
      return unless params.delete(:remove_avatar) == "1"

      resource.avatar.purge
    end
  end
end
