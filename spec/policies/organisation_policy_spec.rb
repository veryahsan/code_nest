# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganisationPolicy, type: :policy do
  subject { described_class.new(user, org) }

  let(:org) { create(:organisation) }
  let(:other_org) { create(:organisation) }

  context "as a super admin" do
    let(:user) { create(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[show edit update]) }
  end

  context "as an organisation admin of the same org" do
    let(:user) { create(:user, :organisation_admin, organisation: org) }

    it { is_expected.to permit_actions(%i[show edit update]) }

    it "permits destroy when admin is the only user" do
      expect(subject.destroy?).to be true
    end

    it "forbids destroy when another user belongs to the org" do
      create(:user, organisation: org)
      expect(subject.destroy?).to be false
    end
  end

  context "as a regular member of the same org" do
    let(:user) { create(:user, organisation: org) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_actions(%i[edit update destroy]) }
  end

  context "as a user of a different org" do
    let(:user) { create(:user, organisation: other_org) }

    it { is_expected.to forbid_actions(%i[show edit update destroy]) }
  end

  describe "Scope" do
    it "returns only the user's organisation for tenant users" do
      user = create(:user, organisation: org)
      create(:organisation)
      result = described_class::Scope.new(user, Organisation.all).resolve
      expect(result).to contain_exactly(org)
    end

    it "returns all orgs for super admin" do
      user = create(:user, :super_admin)
      create(:organisation)
      expect(described_class::Scope.new(user, Organisation.all).resolve.count).to eq(Organisation.count)
    end

    it "returns none for guests" do
      expect(described_class::Scope.new(nil, Organisation.all).resolve).to eq(Organisation.none)
    end
  end
end
