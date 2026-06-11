class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method

  allow_browser versions: :modern

  layout :resolved_layout

  before_action :prepare_sidebar

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Actions opted into the generic show-page overlay. These always render inside
  # the `modal` Turbo Frame — both when reached via a frame request (a link with
  # data-turbo-frame="modal") and on a direct/full load (hard reload, bookmark,
  # typed URL), so the page is the modal rather than a full-page render.
  class_attribute :modal_show_actions, default: [], instance_writer: false

  # Declare which actions should render in the overlay.
  #   show_in_modal :show
  def self.show_in_modal(*actions)
    self.modal_show_actions = actions.map(&:to_sym)
  end

  private

  def modal_show_request?
    self.class.modal_show_actions.include?(action_name.to_sym)
  end

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

  def resolved_layout
    if user_signed_in? && turbo_frame_request?
      return "modal_show" if turbo_frame_request_id == "modal"

      return "turbo_frame"
    end

    # Direct/full load of an overlay action: still render the modal, now on top
    # of the signed-in chrome (see layouts/modal_show.html.erb).
    return "modal_show" if user_signed_in? && modal_show_request?

    "application"
  end

  # The id of the Turbo Frame the current request targets, if any.
  # (Rails sends it in the `Turbo-Frame` request header.)
  def turbo_frame_request_id
    request.headers["Turbo-Frame"]
  end

  # Prepares the structured data the signed-in chrome (sidebar + mobile
  # topbar) needs to render itself.
  def prepare_sidebar
    return unless user_signed_in?
    return if turbo_frame_request?

    @sidebar = SidebarFacade.call(user: current_user, url_helpers: self).value
  end
end
