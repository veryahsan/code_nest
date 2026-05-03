# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organisations::CreationFacade, type: :facade do
  let(:owner) { create(:user, :without_organisation) }

  describe ".call" do
    it "creates the organisation, generates a slug, and links the owner as :admin" do
      result = described_class.call(name: "Brand New Co", owner: owner)

      expect(result).to be_success
      expect(result.value).to have_attributes(
        persisted?: true,
        name: "Brand New Co",
        slug: "brand-new-co",
      )
      expect(owner.reload).to have_attributes(organisation: result.value, org_role: "admin")
    end

    it "disambiguates the slug when one already exists" do
      create(:organisation, slug: "brand-new-co")

      result = described_class.call(name: "Brand New Co", owner: owner)

      expect(result).to be_success
      expect(result.value.slug).to eq("brand-new-co-1")
    end

    it "returns a failure with errors on the organisation when the name is blank" do
      result = described_class.call(name: "", owner: owner)

      expect(result).to be_failure
      expect(result.error).to be_a(Organisation)
      expect(result.error.errors[:name]).to be_present
      expect(Organisation.count).to eq(0)
      expect(owner.reload.organisation).to be_nil
    end

    it "rolls everything back when the owner cannot be assigned" do
      allow(Users::AssignToOrganisationService).to receive(:call).and_return(
        ApplicationService::Result.new(success: false, value: nil, error: "boom"),
      )

      result = described_class.call(name: "Rollback Co", owner: owner)

      expect(result).to be_failure
      expect(result.error.errors[:base]).to include("boom")
      expect(Organisation.where(name: "Rollback Co")).to be_empty
      expect(owner.reload.organisation).to be_nil
    end

    it "does not allow super admins to bootstrap a tenant" do
      super_admin = create(:user, :super_admin)

      result = described_class.call(name: "Forbidden", owner: super_admin)

      expect(result).to be_failure
      expect(Organisation.where(name: "Forbidden")).to be_empty
    end
  end
end
