# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvitationPolicy, type: :policy do
  subject { described_class.new(user, invitation) }

  let(:org) { create(:organisation) }
  let(:invitation) { create(:invitation, organisation: org) }

  context "as an admin in same org" do
    let(:user) { create(:user, :organisation_admin, organisation: org) }

    it { is_expected.to permit_actions(%i[index show create destroy]) }
  end

  context "as a regular member" do
    let(:user) { create(:user, organisation: org) }

    it { is_expected.to forbid_actions(%i[index show create destroy]) }
  end

  context "as an admin in another org" do
    let(:user) { create(:user, :organisation_admin, organisation: create(:organisation)) }

    it { is_expected.to forbid_actions(%i[show destroy]) }
  end
end
