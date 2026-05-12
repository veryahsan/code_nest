# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectDocumentPolicy, type: :policy do
  subject { described_class.new(user, document) }

  let(:org) { create(:organisation) }
  let(:project) { create(:project, organisation: org) }
  let(:document) { create(:project_document, project: project) }

  context "as admin in same org" do
    let(:user) { create(:user, :organisation_admin, organisation: org) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as member" do
    let(:user) { create(:user, organisation: org) }

    it { is_expected.to permit_actions(%i[index show]) }
    it { is_expected.to forbid_actions(%i[create update destroy]) }
  end

  context "as foreign user" do
    let(:user) { create(:user, organisation: create(:organisation)) }

    it { is_expected.to forbid_actions(%i[show update destroy]) }
  end
end
