# frozen_string_literal: true

require "rails_helper"

RSpec.describe SidebarFacade, type: :facade do
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

    it "exposes a primary nav with Dashboard, Messages, Projects, Employees (no admin items)" do
      labels = facade.primary_nav.map(&:label)
      expect(labels).to eq(%w[Dashboard Messages Projects Employees])
    end

    it "only includes the user's own teams (up to MAX_TEAMS_IN_SIDEBAR)" do
      my_team    = create(:team, organisation: org, name: "Alpha")
      other_team = create(:team, organisation: org, name: "Zeta")
      create(:team_membership, team: my_team, user: user)

      names = facade.teams.map(&:name)
      expect(names).to include("Alpha")
      expect(names).not_to include("Zeta")
    end

    it "caps the teams list at MAX_TEAMS_IN_SIDEBAR" do
      (described_class::MAX_TEAMS_IN_SIDEBAR + 3).times do |i|
        team = create(:team, organisation: org, name: "Team #{format('%02d', i)}")
        create(:team_membership, team: team, user: user)
      end

      expect(facade.teams.size).to eq(described_class::MAX_TEAMS_IN_SIDEBAR)
    end

    it "show_teams_section? is true" do
      expect(facade.show_teams_section?).to be true
    end

    it "exposes brand/teams/account/logout hrefs" do
      expect(facade.brand_href).to eq(url_helpers.dashboard_path)
      expect(facade.teams_index_href).to eq(url_helpers.teams_path)
      expect(facade.account_href).to eq(url_helpers.edit_user_registration_path)
      expect(facade.logout_href).to eq(url_helpers.destroy_user_session_path)
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

    it "hides the Teams section" do
      expect(facade.show_teams_section?).to be false
      expect(facade.teams).to eq([])
    end

    it "only surfaces Messages in the primary nav" do
      labels = facade.primary_nav.map(&:label)
      expect(labels).to eq(%w[Messages])
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

    it "hides the Teams section" do
      expect(facade.show_teams_section?).to be false
    end

    it "reports super_admin? true" do
      expect(facade.super_admin?).to be true
    end
  end
end
