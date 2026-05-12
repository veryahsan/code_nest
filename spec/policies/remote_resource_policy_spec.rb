# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemoteResourcePolicy, type: :policy do
  subject { described_class.new(user, resource) }

  let(:org) { create(:organisation) }
  let(:project) { create(:project, organisation: org) }
  let(:resource) { create(:remote_resource, project: project) }

  context "as admin" do
    let(:user) { create(:user, :organisation_admin, organisation: org) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }

    it "permits view_credentials when lockbox is configured" do
      expect(subject.view_credentials?).to be true
    end
  end

  context "as member" do
    let(:user) { create(:user, organisation: org) }

    it { is_expected.to permit_actions(%i[index show]) }
    it { is_expected.to forbid_actions(%i[create update destroy]) }
    it { expect(subject.view_credentials?).to be false }
  end

  context "as foreign user" do
    let(:user) { create(:user, organisation: create(:organisation)) }

    it { is_expected.to forbid_actions(%i[show update destroy]) }
  end
end
