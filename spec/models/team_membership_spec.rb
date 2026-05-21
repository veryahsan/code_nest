# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamMembership, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:team) }
  end

  describe "validations" do
    subject { build(:team_membership) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:team_id) }

    it "allows only one lead per team" do
      team = create(:team, organisation: create(:organisation))
      create(:team_membership, team: team, lead: true)
      second_lead = build(:team_membership, team: team, lead: true)

      expect(second_lead).not_to be_valid
      expect(second_lead.errors[:lead]).to be_present
    end

    it "rejects users outside the team's organisation" do
      org_a = create(:organisation)
      org_b = create(:organisation)
      team = create(:team, organisation: org_a)
      user = create(:user, organisation: org_b)

      membership = build(:team_membership, team: team, user: user)
      expect(membership).not_to be_valid
      expect(membership.errors[:team]).to be_present
    end
  end
end
