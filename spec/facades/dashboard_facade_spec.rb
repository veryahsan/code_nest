# frozen_string_literal: true

require "rails_helper"

RSpec.describe DashboardFacade, type: :facade do
  describe ".call" do
    context "when the user has an organisation" do
      let(:org)  { create(:organisation) }
      let(:user) { create(:user, organisation: org) }

      before do
        create(:team, organisation: org, name: "Alpha")
        create(:team, organisation: org, name: "Beta")
        create(:project, organisation: org, name: "Widget")
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

      it "exposes teams ordered by name with users eager-loaded" do
        facade = described_class.call(user: user).value
        expect(facade.teams.map(&:name)).to eq(%w[Alpha Beta])
        expect(facade.teams).to be_loaded
      end

      it "exposes projects ordered by name with team eager-loaded" do
        facade = described_class.call(user: user).value
        expect(facade.projects.map(&:name)).to eq(%w[Widget])
        expect(facade.projects).to be_loaded
      end

      it "exposes up to 10 pending invitations ordered most-recent-first" do
        facade = described_class.call(user: user).value
        expect(facade.pending_invitations).to be_present
      end

      it "is not in onboarding state" do
        expect(described_class.call(user: user).value.onboarding?).to be false
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

      it "leaves teams, projects, and pending_invitations nil" do
        facade = described_class.call(user: user).value
        expect(facade.teams).to be_nil
        expect(facade.projects).to be_nil
        expect(facade.pending_invitations).to be_nil
      end
    end
  end
end
