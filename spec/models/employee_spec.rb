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

  describe "handle generation" do
    let(:org) { create(:organisation) }

    it "auto-generates a handle from the email local-part on create" do
      user = create(:user, organisation: org, email: "ada.lovelace@example.com")
      employee = create(:employee, user: user, organisation: org)

      expect(employee.handle).to eq("ada_lovelace")
    end

    it "appends a random suffix when the base is already taken in the org" do
      first = create(:user, organisation: org, email: "sam@example.com")
      second = create(:user, organisation: org, email: "sam@other.com")
      create(:employee, user: first, organisation: org)

      employee = create(:employee, user: second, organisation: org)

      expect(employee.handle).to start_with("sam_")
      expect(employee.handle).to match(/\Asam_[a-z0-9]{6}\z/)
    end

    it "allows the same handle in different organisations" do
      other_org = create(:organisation)
      user_a = create(:user, organisation: org, email: "lee@example.com")
      user_b = create(:user, organisation: other_org, email: "lee@elsewhere.com")

      create(:employee, user: user_a, organisation: org)
      employee_b = create(:employee, user: user_b, organisation: other_org)

      expect(employee_b.handle).to eq("lee")
    end

    it "honours an explicitly provided handle" do
      user = create(:user, organisation: org)
      employee = create(:employee, user: user, organisation: org, handle: "custom_handle")

      expect(employee.handle).to eq("custom_handle")
    end

    it "rejects a handle outside the allowed grammar" do
      employee = build(:employee, organisation: org, handle: "Has Spaces")
      expect(employee).not_to be_valid
      expect(employee.errors[:handle]).to be_present
    end

    it "enforces uniqueness within an organisation (case-insensitive)" do
      user_a = create(:user, organisation: org)
      user_b = create(:user, organisation: org)
      create(:employee, user: user_a, organisation: org, handle: "dupe")

      clash = build(:employee, user: user_b, organisation: org, handle: "DUPE")
      expect(clash).not_to be_valid
      expect(clash.errors[:handle]).to be_present
    end
  end
end
