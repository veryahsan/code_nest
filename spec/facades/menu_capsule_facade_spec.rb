# frozen_string_literal: true

require "rails_helper"

RSpec.describe MenuCapsuleFacade, type: :facade do
  let(:url_helpers) { Rails.application.routes.url_helpers }

  describe "for a regular organisation member" do
    let(:org)  { create(:organisation) }
    let(:user) { create(:user, organisation: org) }

    subject(:facade) { described_class.call(user: user, url_helpers: url_helpers).value }

    it "exposes the user's display_name (email local-part)" do
      expect(facade.display_name).to eq(user.email.split("@").first)
    end

    it "reports has_organisation? true and admin/super false" do
      expect(facade.has_organisation?).to be true
      expect(facade.organisation_admin?).to be false
      expect(facade.super_admin?).to be false
    end

    it "exposes a primary nav with Dashboard, Projects, Employees (no Messages or admin items)" do
      labels = facade.primary_nav.map(&:label)
      expect(labels).to eq(%w[Dashboard Projects Employees])
    end

    it "only includes the user's own projects (up to MAX_PROJECTS_IN_MENU_CAPSULE)" do
      mine   = create(:project, organisation: org, name: "Alpha")
      create(:project, organisation: org, name: "Zeta")
      create(:project_membership, project: mine, user: user)

      names = facade.projects.map(&:name)
      expect(names).to include("Alpha")
      expect(names).not_to include("Zeta")
    end

    it "caps the projects list at MAX_PROJECTS_IN_MENU_CAPSULE" do
      (described_class::MAX_PROJECTS_IN_MENU_CAPSULE + 3).times do |i|
        project = create(:project, organisation: org, name: "Project #{format('%02d', i)}")
        create(:project_membership, project: project, user: user)
      end

      expect(facade.projects.size).to eq(described_class::MAX_PROJECTS_IN_MENU_CAPSULE)
    end

    it "show_projects_section? is true" do
      expect(facade.show_projects_section?).to be true
    end

    it "exposes brand/projects/account/logout hrefs" do
      expect(facade.brand_href).to eq(url_helpers.dashboard_path)
      expect(facade.projects_index_href).to eq(url_helpers.projects_path)
      expect(facade.account_href).to eq(url_helpers.edit_user_registration_path)
      expect(facade.logout_href).to eq(url_helpers.destroy_user_session_path)
    end

    it "exposes the notifications index href" do
      expect(facade.notifications_index_href).to eq(url_helpers.notifications_path)
    end
  end

  describe "notifications" do
    let(:org)   { create(:organisation) }
    let(:user)  { create(:user, organisation: org) }
    let(:actor) { create(:user, organisation: org) }
    let(:conversation) { create(:conversation, organisation: org) }

    subject(:facade) { described_class.call(user: user, url_helpers: url_helpers).value }

    def notify!(read: false)
      message = create(:message, user: actor, conversation: conversation)
      Notification.create!(recipient: user, actor: actor, notifiable: message,
                           kind: "message_created", read_at: read ? Time.current : nil)
    end

    it "counts only the user's unread notifications" do
      notify!
      notify!
      notify!(read: true)
      create(:notification) # belongs to some other user

      expect(facade.unread_notifications_count).to eq(2)
    end

    it "returns recent notifications newest-first, capped at the limit" do
      oldest = notify!
      newest = nil
      (described_class::RECENT_NOTIFICATIONS_LIMIT + 2).times { newest = notify! }

      expect(facade.recent_notifications.size).to eq(described_class::RECENT_NOTIFICATIONS_LIMIT)
      expect(facade.recent_notifications.first).to eq(newest)
      expect(facade.recent_notifications).not_to include(oldest)
    end

    it "defaults to zero unread and an empty list when there is nothing" do
      expect(facade.unread_notifications_count).to eq(0)
      expect(facade.recent_notifications).to eq([])
    end
  end

  describe "for an organisation admin" do
    let(:org)   { create(:organisation) }
    let(:admin) { create(:user, :organisation_admin, organisation: org) }

    subject(:facade) { described_class.call(user: admin, url_helpers: url_helpers).value }

    it "includes admin-only items (Invitations, Organisation)" do
      labels = facade.primary_nav.map(&:label)
      expect(labels).to include("Invitations", "Organisation")
    end

    it "reports organisation_admin? true" do
      expect(facade.organisation_admin?).to be true
    end
  end

  describe "for an org-less user (onboarding state)" do
    let(:user) { create(:user, :without_organisation) }

    subject(:facade) { described_class.call(user: user, url_helpers: url_helpers).value }

    it "has_organisation? is false" do
      expect(facade.has_organisation?).to be false
    end

    it "hides the Projects section" do
      expect(facade.show_projects_section?).to be false
      expect(facade.projects).to eq([])
    end

    it "surfaces no primary nav items (no organisation yet)" do
      expect(facade.primary_nav).to eq([])
    end

    it "hides the Messages section" do
      expect(facade.show_messages_section?).to be false
      expect(facade.conversations).to eq([])
    end

    it "brand_href falls back to root" do
      expect(facade.brand_href).to eq(url_helpers.root_path)
    end
  end

  describe "for a platform super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    subject(:facade) { described_class.call(user: super_admin, url_helpers: url_helpers).value }

    it "exposes only the Admin nav item" do
      labels = facade.primary_nav.map(&:label)
      expect(labels).to eq(%w[Admin])
    end

    it "hides the Projects section" do
      expect(facade.show_projects_section?).to be false
    end

    it "reports super_admin? true" do
      expect(facade.super_admin?).to be true
    end

    it "hides the Messages section" do
      expect(facade.show_messages_section?).to be false
      expect(facade.conversations).to eq([])
    end
  end

  describe "messages section" do
    let(:org)   { create(:organisation) }
    let(:user)  { create(:user, organisation: org) }
    let(:other) { create(:user, organisation: org) }

    subject(:facade) { described_class.call(user: user, url_helpers: url_helpers).value }

    it "show_messages_section? is true for an org member" do
      expect(facade.show_messages_section?).to be true
    end

    it "lists the user's conversations newest-first" do
      older = create(:conversation, organisation: org, title: "Older")
      newer = create(:conversation, organisation: org, title: "Newer")
      [ older, newer ].each { |c| c.add_participant(user) }
      older.update_column(:updated_at, 1.hour.ago)

      titles = facade.conversations.map(&:title)
      expect(titles).to eq(%w[Newer Older])
    end

    it "names a direct conversation after the other participant" do
      dm = create(:conversation, :direct, organisation: org)
      dm.add_participant(user)
      dm.add_participant(other)

      entry = facade.conversations.first
      expect(entry.direct?).to be true
      expect(entry.title).to eq(Conversation.participant_label(other))
    end

    it "uses the group title for group conversations" do
      group = create(:conversation, organisation: org, title: "Roadmap")
      group.add_participant(user)

      expect(facade.conversations.first.title).to eq("Roadmap")
    end

    it "counts messages from others received after the user last read" do
      conversation = create(:conversation, organisation: org)
      conversation.add_participant(user)
      conversation.add_participant(other)

      create(:message, conversation: conversation, user: other)
      create(:message, conversation: conversation, user: other)
      create(:message, conversation: conversation, user: user) # own message: not counted

      expect(facade.conversations.first.unread_count).to eq(2)
    end

    it "excludes messages received before the last_read_at watermark" do
      conversation = create(:conversation, organisation: org)
      conversation.add_participant(user)
      conversation.add_participant(other)

      create(:message, conversation: conversation, user: other, created_at: 2.hours.ago)
      conversation.conversation_participants
                  .find_by(user: user)
                  .update_column(:last_read_at, 1.hour.ago)
      create(:message, conversation: conversation, user: other)

      expect(facade.conversations.first.unread_count).to eq(1)
    end

    it "caps the conversation list at MAX_CONVERSATIONS_IN_MENU_CAPSULE" do
      (described_class::MAX_CONVERSATIONS_IN_MENU_CAPSULE + 2).times do |i|
        c = create(:conversation, organisation: org, title: "Chat #{i}")
        c.add_participant(user)
      end

      expect(facade.conversations.size).to eq(described_class::MAX_CONVERSATIONS_IN_MENU_CAPSULE)
    end
  end
end
