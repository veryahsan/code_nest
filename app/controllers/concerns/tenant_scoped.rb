# frozen_string_literal: true

# Mixed into every Hotwire controller that operates on tenant-owned data
# (Teams, Projects, Employees, Invitations, etc.). Provides:
#
#   * #current_organisation — convenience for current_user.organisation
#   * #require_organisation! — bounces org-less or super-admin users back
#     to the dashboard so the rest of the controller can assume the user
#     belongs to a tenant
#   * #require_organisation_admin! — locks down write actions
#
# The Pundit policies still gate per-action authorisation; this concern is
# the cheap structural guard so policies never have to second-guess "does
# this user even have an organisation?".
module TenantScoped
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :require_organisation!
    helper_method :current_organisation
  end

  def current_organisation
    current_user&.organisation
  end

  private

  def require_organisation!
    return if current_user&.super_admin?
    return if current_organisation.present?

    redirect_to dashboard_path,
                alert: "Join or create an organisation before using this area."
  end

  def require_organisation_admin!
    return if current_user&.super_admin?
    return if current_user&.org_admin? && current_organisation.present?

    redirect_to dashboard_path, alert: "Only organisation admins can do that."
  end
end
