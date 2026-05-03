# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::PostConfirmationFacade, type: :facade do
  let!(:acme) { create(:organisation, slug: "acme-pcf-1") }
  let!(:acme_member) { create(:user, organisation: acme, email: "alice@acme-pcf.dev") }

  describe ".call" do
    it "auto-attaches a user whose email domain already lives in some organisation" do
      newcomer = create(
        :user,
        :without_organisation,
        email: "bob@acme-pcf.dev",
      )

      result = described_class.call(user: newcomer)

      expect(result).to be_success
      expect(newcomer.reload.organisation).to eq(acme)
      expect(newcomer).to be_org_member
    end

    it "no-ops when the user already belongs to an organisation" do
      already_in_org = create(:user, organisation: create(:organisation), email: "x@acme-pcf.dev")
      allow(Organisations::FindByEmailDomainService).to receive(:call)

      result = described_class.call(user: already_in_org)

      expect(result).to be_success
      expect(Organisations::FindByEmailDomainService).not_to have_received(:call)
    end

    it "no-ops for super admins" do
      super_admin = create(:user, :super_admin, email: "platform@acme-pcf.dev")
      allow(Organisations::FindByEmailDomainService).to receive(:call)

      result = described_class.call(user: super_admin)

      expect(result).to be_success
      expect(super_admin.reload.organisation).to be_nil
      expect(Organisations::FindByEmailDomainService).not_to have_received(:call)
    end

    it "leaves the user org-less when no existing user shares the domain" do
      lonely = create(:user, :without_organisation, email: "founder@unique-domain.example")

      result = described_class.call(user: lonely)

      expect(result).to be_success
      expect(lonely.reload.organisation).to be_nil
    end

    it "propagates assignment failures as a failure result" do
      newcomer = create(:user, :without_organisation, email: "bob@acme-pcf.dev")
      allow(Users::AssignToOrganisationService).to receive(:call).and_return(
        ApplicationService::Result.new(success: false, value: nil, error: "kaboom"),
      )

      result = described_class.call(user: newcomer)

      expect(result).to be_failure
      expect(result.error).to eq("kaboom")
    end

    it "ensures the seed user is referenced (factory dependency)" do
      expect(acme_member).to be_persisted
    end
  end
end
