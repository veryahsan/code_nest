# frozen_string_literal: true

require "rails_helper"

RSpec.describe DashboardFacade, type: :facade do
  describe ".call" do
    context "when the user has an organisation (non-admin member)" do
      let(:org)  { create(:organisation) }
      let(:user) { create(:user, organisation: org) }

      let!(:my_team)    { create(:team, organisation: org, name: "Alpha") }
      let!(:other_team) { create(:team, organisation: org, name: "Zeta") }

      let!(:my_project)    { create(:project, organisation: org, name: "Widget", team: my_team) }
      let!(:other_project) { create(:project, organisation: org, name: "Gizmo",  team: other_team) }
      let!(:unassigned)    { create(:project, organisation: org, name: "Orphan", team: nil) }

      before do
        create(:team_membership, team: my_team, user: user)
        create(:invitation, organisation: org)
      end

      it "succeeds and returns self as the value" do
        result = described_class.call(user: user)
        expect(result).to be_success
        expect(result.value).to be_a(described_class)
      end

      it "exposes the organisation" do
        facade = described_class.call(user: user).value
        expect(facade.organisation).to eq(org)
      end

      it "exposes only the user's own teams, ordered by name with users eager-loaded" do
        facade = described_class.call(user: user).value
        expect(facade.teams.map(&:name)).to eq(%w[Alpha])
        expect(facade.teams).to be_loaded
      end

      it "exposes only projects belonging to the user's teams" do
        facade = described_class.call(user: user).value
        expect(facade.projects.map(&:name)).to eq(%w[Widget])
        expect(facade.projects).to be_loaded
      end

      it "does not expose pending invitations for regular members" do
        facade = described_class.call(user: user).value
        expect(facade.pending_invitations).to be_nil
      end

      it "exposes the user's employee record (nil when none exists)" do
        facade = described_class.call(user: user).value
        expect(facade.employee).to be_nil

        create(:employee, organisation: org, user: user)
        facade = described_class.call(user: user).value
        expect(facade.employee).to be_present
      end

      it "exposes the user's direct reports (empty when there is no employee record)" do
        facade = described_class.call(user: user).value
        expect(facade.direct_reports).to eq([])
      end

      it "is not in onboarding state" do
        expect(described_class.call(user: user).value.onboarding?).to be false
      end

      it "reports mode as :member_workspace" do
        expect(described_class.call(user: user).value.mode).to eq(:member_workspace)
      end

      it "does not populate admin-only analytics readers" do
        facade = described_class.call(user: user).value
        expect(facade.members_total).to be_nil
        expect(facade.top_teams_by_members).to be_nil
      end
    end

    context "when the user has no organisation yet" do
      let(:user) { create(:user, :without_organisation) }

      it "succeeds" do
        expect(described_class.call(user: user)).to be_success
      end

      it "reports onboarding? as true" do
        expect(described_class.call(user: user).value.onboarding?).to be true
      end

      it "reports mode as :onboarding" do
        expect(described_class.call(user: user).value.mode).to eq(:onboarding)
      end

      it "leaves teams, projects, and pending_invitations nil" do
        facade = described_class.call(user: user).value
        expect(facade.teams).to be_nil
        expect(facade.projects).to be_nil
        expect(facade.pending_invitations).to be_nil
      end
    end

    context "when the user is an organisation admin" do
      let(:org)   { create(:organisation) }
      let(:admin) { create(:user, :organisation_admin, organisation: org) }

      let!(:team_alpha) { create(:team, organisation: org, name: "Alpha") }
      let!(:team_beta)  { create(:team, organisation: org, name: "Beta") }

      before do
        teamed_member = create(:user, organisation: org)
        create(:user, organisation: org) # orphan_member — intentionally on no team

        create(:team_membership, team: team_alpha, user: admin)
        create(:team_membership, team: team_alpha, user: teamed_member)

        create(:project, organisation: org, name: "Widget", team: team_alpha)
        create(:project, organisation: org, name: "Gizmo", team: nil)

        # Reuse the admin as the inviter so we don't accidentally spawn extra
        # users in the organisation and skew the analytics counters.
        create(:invitation, organisation: org, invited_by: admin)
        create(:invitation, organisation: org, invited_by: admin,
                            accepted_at: Time.current)

        create(:employee, organisation: org, user: admin)
      end

      it "reports mode as :admin_analytics" do
        expect(described_class.call(user: admin).value.mode).to eq(:admin_analytics)
      end

      it "exposes workspace readers alongside analytics" do
        facade = described_class.call(user: admin).value
        expect(facade.teams.map(&:name)).to eq(%w[Alpha Beta])
        expect(facade.projects.map(&:name)).to eq(%w[Gizmo Widget])
        expect(facade.pending_invitations).to be_present
      end

      it "counts organisation members and role breakdown" do
        facade = described_class.call(user: admin).value
        expect(facade.members_total).to eq(3)
        expect(facade.admins_count).to eq(1)
        expect(facade.members_count).to eq(2)
      end

      it "counts teams, projects, and employees in the organisation" do
        facade = described_class.call(user: admin).value
        expect(facade.teams_total).to eq(2)
        expect(facade.projects_total).to eq(2)
        expect(facade.employees_total).to eq(1)
      end

      it "counts org-health gaps" do
        facade = described_class.call(user: admin).value
        expect(facade.unassigned_projects_count).to eq(1)
        expect(facade.users_without_team_count).to eq(1)
        expect(facade.employees_without_manager_count).to eq(1)
      end

      it "splits invitations between pending and accepted" do
        facade = described_class.call(user: admin).value
        expect(facade.pending_invitations_count).to eq(1)
        expect(facade.accepted_invitations_count).to eq(1)
      end

      it "counts items created in the last 7 days" do
        facade = described_class.call(user: admin).value
        expect(facade.new_users_last_7d).to be >= 3
        expect(facade.new_teams_last_7d).to eq(2)
        expect(facade.new_projects_last_7d).to eq(2)
      end

      it "returns the top 5 teams by members ordered desc" do
        facade = described_class.call(user: admin).value
        top = facade.top_teams_by_members.to_a
        expect(top.length).to be <= 5
        expect(top.first).to eq(team_alpha)
        expect(top.first.team_members_count).to eq(2)
      end

      it "returns the top 5 teams by projects ordered desc" do
        facade = described_class.call(user: admin).value
        top = facade.top_teams_by_projects.to_a
        expect(top.length).to be <= 5
        expect(top.first).to eq(team_alpha)
        expect(top.first.team_projects_count).to eq(1)
      end
    end
  end
end
