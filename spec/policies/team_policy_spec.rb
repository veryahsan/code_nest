# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamPolicy, type: :policy do
  subject { described_class.new(user, team) }

  let(:org) { create(:organisation) }
  let(:team) { create(:team, organisation: org) }

  context "as a super admin" do
    let(:user) { create(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as an org admin in the same org" do
    let(:user) { create(:user, :organisation_admin, organisation: org) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as a member in the same org" do
    let(:user) { create(:user, organisation: org) }

    it { is_expected.to permit_actions(%i[index show]) }
    it { is_expected.to forbid_actions(%i[create update destroy]) }
  end

  context "as a user from another org" do
    let(:user) { create(:user, organisation: create(:organisation)) }

    it { is_expected.to forbid_actions(%i[show update destroy]) }
  end

  context "as a guest" do
    let(:user) { nil }

    it { is_expected.to forbid_actions(%i[index show create update destroy]) }
  end
end
