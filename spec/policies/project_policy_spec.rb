# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectPolicy, type: :policy do
  subject { described_class.new(user, project) }

  let(:org) { create(:organisation) }
  let(:team) { create(:team, organisation: org) }
  let(:project) { create(:project, organisation: org, team: team) }

  context "as an admin in same org" do
    let(:user) { create(:user, :organisation_admin, organisation: org) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as a member of the project's team" do
    let(:user) { create(:user, organisation: org) }

    before { create(:team_membership, team: team, user: user) }

    it { is_expected.to permit_actions(%i[index show]) }
    it { is_expected.to forbid_actions(%i[create update destroy]) }
  end

  context "as a member in the same org who is NOT on the project's team" do
    let(:user) { create(:user, organisation: org) }

    it { is_expected.to permit_actions(%i[index]) }
    it { is_expected.to forbid_actions(%i[show create update destroy]) }
  end

  context "as a member in the same org viewing an unassigned project" do
    let(:project) { create(:project, organisation: org, team: nil) }
    let(:user) { create(:user, organisation: org) }

    it { is_expected.to permit_actions(%i[index]) }
    it { is_expected.to forbid_actions(%i[show create update destroy]) }
  end

  context "as a foreign user" do
    let(:user) { create(:user, organisation: create(:organisation)) }

    it { is_expected.to forbid_actions(%i[show update destroy]) }
  end
end
