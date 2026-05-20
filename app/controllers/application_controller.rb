class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method

  allow_browser versions: :modern

  before_action :prepare_sidebar

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized(_exception)
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  def after_sign_in_path_for(resource)
    return admin_root_path if resource.try(:super_admin?)

    dashboard_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  # Prepares the structured data the signed-in chrome (sidebar + mobile
  # topbar) needs to render itself.
  def prepare_sidebar
    return unless user_signed_in?

    @sidebar = SidebarFacade.call(user: current_user, url_helpers: self).value
  end
end
