# frozen_string_literal: true

require "rails_helper"

RSpec.describe Employee, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organisation) }
    it { is_expected.to belong_to(:manager).optional }
    it { is_expected.to have_many(:direct_reports).dependent(:nullify) }
  end

  describe "validations" do
    subject { build(:employee) }

    it { is_expected.to validate_uniqueness_of(:user_id) }

    it "rejects super admins" do
      admin = build(:user, :super_admin)
      employee = build(:employee, user: admin, organisation: create(:organisation))
      expect(employee).not_to be_valid
      expect(employee.errors[:user]).to be_present
    end

    it "requires the user's organisation to match" do
      org_user = create(:organisation)
      org_other = create(:organisation)
      user = create(:user, organisation: org_user)

      employee = build(:employee, user: user, organisation: org_other)
      expect(employee).not_to be_valid
      expect(employee.errors[:organisation]).to be_present
    end

    it "requires the manager to share the organisation" do
      org_a = create(:organisation)
      org_b = create(:organisation)
      wrong_manager = create(:employee, organisation: org_b)
      user = create(:user, organisation: org_a)

      employee = build(:employee, user: user, organisation: org_a, manager: wrong_manager)
      expect(employee).not_to be_valid
      expect(employee.errors[:manager]).to be_present
    end

    it "does not allow an employee to be their own manager once persisted" do
      employee = create(:employee)
      employee.manager_id = employee.id
      expect(employee).not_to be_valid
      expect(employee.errors[:manager]).to be_present
    end
  end
end
