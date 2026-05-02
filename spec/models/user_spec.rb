# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:team_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:team_memberships) }
    it { is_expected.to have_one(:employee).dependent(:destroy) }
    it { is_expected.to have_many(:sent_invitations).dependent(:nullify) }

    it "associates at most one organisation" do
      org = create(:organisation)
      user = create(:user, organisation: org)
      expect(user.organisation).to eq(org)
      expect(org.users).to include(user)
    end
  end

  describe "validations" do
    it "requires an organisation for normal users" do
      user = build(:user, organisation: nil, super_admin: false)
      expect(user).not_to be_valid
      expect(user.errors[:organisation]).to include("can't be blank")
    end

    it "allows no organisation for platform super admins" do
      user = build(:user, :super_admin)
      expect(user).to be_valid
    end

    it "does not allow an organisation on super admins" do
      org = create(:organisation)
      user = build(:user, :super_admin)
      user.organisation = org
      expect(user).not_to be_valid
      expect(user.errors[:organisation_id]).to be_present
    end
  end

  describe "roles" do
    it "defaults to member" do
      expect(build(:user).org_member?).to be true
    end

    it "organisation_admin? reflects org admin role" do
      expect(build(:user).organisation_admin?).to be false
      expect(build(:user, :organisation_admin).organisation_admin?).to be true
    end
  end
end
