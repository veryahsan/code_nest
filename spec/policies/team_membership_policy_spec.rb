# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamMembershipPolicy, type: :policy do
  subject { described_class.new(user, membership) }

  let(:org) { create(:organisation) }
  let(:team) { create(:team, organisation: org) }
  let(:membership) { build(:team_membership, team: team) }

  context "as an org admin" do
    let(:user) { create(:user, :organisation_admin, organisation: org) }

    it { is_expected.to permit_actions(%i[create destroy]) }
  end

  context "as a member of the same org" do
    let(:user) { create(:user, organisation: org) }

    it { is_expected.to forbid_actions(%i[create destroy]) }
  end

  context "as a super admin" do
    let(:user) { create(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[create destroy]) }
  end

  context "as a user from another org" do
    let(:user) { create(:user, organisation: create(:organisation)) }

    it { is_expected.to forbid_actions(%i[create destroy]) }
  end
end
