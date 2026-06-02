# frozen_string_literal: true

# Packages everything the signed-in chrome (`shared/_sidebar.html.erb` +
# `shared/_mobile_topbar.html.erb`) needs to render itself, so the views
# never have to query the model layer or branch on user role inline.
#
# Set on the request via the `prepare_sidebar` before_action in
# `ApplicationController`. Views read structured fields from `@sidebar`.
class SidebarFacade < ApplicationFacade
  MAX_PROJECTS_IN_SIDEBAR      = 8
  MAX_CONVERSATIONS_IN_SIDEBAR = 12

  ProjectEntry      = Struct.new(:name, :href, keyword_init: true)
  NavItem           = Struct.new(:label, :href, :icon, keyword_init: true)
  ConversationEntry = Struct.new(:id, :title, :href, :unread_count, :direct, keyword_init: true) do
    def direct? = direct
  end

  RECENT_NOTIFICATIONS_LIMIT = 10

  attr_reader :user, :avatar_user, :display_name,
              :projects, :primary_nav, :conversations,
              :brand_href, :projects_index_href, :messages_index_href,
              :account_href, :logout_href,
              :unread_notifications_count, :recent_notifications,
              :notifications_index_href

  def initialize(user:, url_helpers:)
    @user = user
    @h    = url_helpers
  end

  def call
    @has_organisation    = @user.organisation.present?
    @organisation_admin  = !!@user.org_admin?
    @super_admin         = !!@user.super_admin?
    @avatar_user         = @user
    @display_name        = @user.email.to_s.split("@").first

    @brand_href           = @has_organisation ? @h.dashboard_path : @h.root_path
    @projects_index_href  = @h.projects_path
    @messages_index_href  = @h.messages_path
    @account_href         = @h.edit_user_registration_path
    @logout_href          = @h.destroy_user_session_path

    @projects      = build_project_entries
    @primary_nav   = build_primary_nav
    @conversations = build_conversations

    @notifications_index_href   = @h.notifications_path
    @recent_notifications       = build_recent_notifications
    @unread_notifications_count = @user.notifications.unread.count

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

  def projects?
    @projects.any?
  end

  def show_projects_section?
    @has_organisation && !@super_admin
  end

  def show_messages_section?
    @has_organisation && !@super_admin
  end

  def conversations?
    @conversations.any?
  end

  private

  def build_project_entries
    return [] unless show_projects_section?

    @user.projects.order(:name).limit(MAX_PROJECTS_IN_SIDEBAR).map do |project|
      ProjectEntry.new(name: project.name, href: @h.project_path(project))
    end
  end

  def build_recent_notifications
    @user.notifications
         .recent
         .includes(:actor, :notifiable)
         .limit(RECENT_NOTIFICATIONS_LIMIT)
         .to_a
  end

  def build_primary_nav
    return super_admin_nav if @super_admin
    return [] unless @has_organisation

    items = [
      NavItem.new(label: "Dashboard", href: @h.dashboard_path,   icon: :dashboard),
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

  # The user's most recently active conversations, each with the count of
  # messages that arrived (from someone else) since they last read it.
  def build_conversations
    return [] unless show_messages_section?

    convos = @user.conversations
                  .includes(:participants)
                  .order(updated_at: :desc)
                  .limit(MAX_CONVERSATIONS_IN_SIDEBAR)
                  .to_a
    return [] if convos.empty?

    counts = unread_message_counts(convos.map(&:id))

    convos.map do |conversation|
      ConversationEntry.new(
        id:           conversation.id,
        title:        conversation.display_title(@user),
        href:         @h.conversation_path(conversation),
        unread_count: counts.fetch(conversation.id, 0),
        direct:       conversation.direct?,
      )
    end
  end

  # One grouped query: unread = messages newer than this user's last_read_at
  # for each conversation, excluding messages the user sent themselves.
  def unread_message_counts(conversation_ids)
    Message
      .joins(conversation: :conversation_participants)
      .where(conversation_id: conversation_ids)
      .where(conversation_participants: { user_id: @user.id })
      .where.not(messages: { user_id: @user.id })
      .where("messages.created_at > COALESCE(conversation_participants.last_read_at, ?)", Time.at(0))
      .group("messages.conversation_id")
      .count
  end
end
