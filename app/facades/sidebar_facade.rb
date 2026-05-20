# frozen_string_literal: true

# Packages everything the signed-in chrome (`shared/_sidebar.html.erb` +
# `shared/_mobile_topbar.html.erb`) needs to render itself, so the views
# never have to query the model layer or branch on user role inline.
#
# Set on the request via the `prepare_sidebar` before_action in
# `ApplicationController`. Views read structured fields from `@sidebar`.
class SidebarFacade < ApplicationFacade
  MAX_TEAMS_IN_SIDEBAR = 8

  TeamEntry = Struct.new(:name, :href, keyword_init: true)
  NavItem   = Struct.new(:label, :href, :icon, keyword_init: true)

  attr_reader :user, :avatar_user, :display_name,
              :teams, :primary_nav,
              :brand_href, :teams_index_href,
              :account_href, :logout_href

  def initialize(user:, url_helpers:)
    @user = user
    @h    = url_helpers
  end

  def call
    @has_organisation   = @user.organisation.present?
    @organisation_admin = !!@user.org_admin?
    @super_admin        = !!@user.super_admin?
    @avatar_user        = @user
    @display_name       = @user.email.to_s.split("@").first

    @brand_href        = @has_organisation ? @h.dashboard_path : @h.root_path
    @teams_index_href  = @h.teams_path
    @account_href      = @h.edit_user_registration_path
    @logout_href       = @h.destroy_user_session_path

    @teams       = build_team_entries
    @primary_nav = build_primary_nav

    success(self)
  end

  def has_organisation?
    @has_organisation
  end

  def organisation_admin?
    @organisation_admin
  end

  def super_admin?
    @super_admin
  end

  def teams?
    @teams.any?
  end

  def show_teams_section?
    @has_organisation && !@super_admin
  end

  private

  def build_team_entries
    return [] unless show_teams_section?

    @user.teams.order(:name).limit(MAX_TEAMS_IN_SIDEBAR).map do |team|
      TeamEntry.new(name: team.name, href: @h.team_path(team))
    end
  end

  def build_primary_nav
    return super_admin_nav if @super_admin
    return [ NavItem.new(label: "Messages", href: @h.messages_path, icon: :messages) ] unless @has_organisation

    items = [
      NavItem.new(label: "Dashboard", href: @h.dashboard_path,   icon: :dashboard),
      NavItem.new(label: "Messages",  href: @h.messages_path,    icon: :messages),
      NavItem.new(label: "Projects",  href: @h.projects_path,    icon: :projects),
      NavItem.new(label: "Employees", href: @h.employees_path,   icon: :employees),
    ]

    if @organisation_admin
      items << NavItem.new(label: "Invitations",  href: @h.invitations_path,                       icon: :invitations)
      items << NavItem.new(label: "Organisation", href: @h.organisation_path(@user.organisation),  icon: :organisation)
    end

    items
  end

  def super_admin_nav
    [ NavItem.new(label: "Admin", href: @h.admin_root_path, icon: :admin) ]
  end
end
