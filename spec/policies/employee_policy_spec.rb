# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmployeePolicy, type: :policy do
  subject { described_class.new(user, employee) }

  let(:org) { create(:organisation) }
  let(:employee) { create(:employee, organisation: org) }

  context "as an admin in same org" do
    let(:user) { create(:user, :organisation_admin, organisation: org) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as a member in same org" do
    let(:user) { create(:user, organisation: org) }

    it { is_expected.to permit_actions(%i[index show]) }
    it { is_expected.to forbid_actions(%i[create update destroy]) }
  end

  context "as a foreign user" do
    let(:user) { create(:user, organisation: create(:organisation)) }

    it { is_expected.to forbid_actions(%i[show update destroy]) }
  end
end
