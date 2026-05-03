# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::AssignToOrganisationService, type: :service do
  let(:org) { create(:organisation) }
  let(:user) { create(:user, :without_organisation) }

  describe ".call" do
    it "links the user to the organisation as a :member by default" do
      result = described_class.call(user: user, organisation: org)

      expect(result).to be_success
      expect(user.reload.organisation).to eq(org)
      expect(user).to be_org_member
    end

    it "accepts an explicit :admin role" do
      result = described_class.call(user: user, organisation: org, role: :admin)

      expect(result).to be_success
      expect(user.reload).to be_org_admin
    end

    it "rejects unknown roles without writing" do
      result = described_class.call(user: user, organisation: org, role: :owner)

      expect(result).to be_failure
      expect(result.error).to match(/role/i)
      expect(user.reload.organisation).to be_nil
    end

    it "refuses to link super admins to an organisation" do
      super_admin = create(:user, :super_admin)

      result = described_class.call(user: super_admin, organisation: org, role: :member)

      expect(result).to be_failure
      expect(result.error).to match(/super admin/i)
      expect(super_admin.reload.organisation).to be_nil
    end

    it "surfaces validation errors as a failure" do
      errors = ActiveModel::Errors.new(user)
      errors.add(:organisation, "is invalid for some reason")
      allow(user).to receive_messages(update: false, errors: errors)

      result = described_class.call(user: user, organisation: org, role: :member)

      expect(result).to be_failure
      expect(result.error).to include("is invalid for some reason")
    end
  end
end
