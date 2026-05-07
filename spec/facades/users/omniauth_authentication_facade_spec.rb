# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::OmniauthAuthenticationFacade, type: :facade do
  let(:auth) do
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-uid-1",
      info: { email: "Sam@Acme-Sso.dev", name: "Sam Sample" },
      extra: { raw_info: { "hd" => "acme-sso.dev" } },
    )
  end

  describe ".call" do
    context "when an identity already exists for that (provider, uid)" do
      it "returns its user without creating anything new" do
        existing_user = create(:user)
        create(:identity, user: existing_user, provider: "google_oauth2", uid: "google-uid-1")

        expect {
          result = described_class.call(auth: auth)
          expect(result).to be_success
          expect(result.value).to eq(existing_user)
        }.not_to change { [User.count, Identity.count] }
      end
    end

    context "when current_user is signed in (manual link from settings)" do
      it "links a new identity to that user via LinkOmniauthIdentityService" do
        signed_in_user = create(:user, email: "sam@acme-sso.dev")

        expect {
          result = described_class.call(auth: auth, current_user: signed_in_user)
          expect(result).to be_success
          expect(result.value).to eq(signed_in_user)
        }.to change { signed_in_user.identities.count }.by(1)

        identity = signed_in_user.identities.last
        expect(identity.provider).to eq("google_oauth2")
        expect(identity.uid).to eq("google-uid-1")
      end

      it "prefers an existing identity over the current_user branch" do
        signed_in_user = create(:user, email: "different@acme-sso.dev")
        existing_owner = create(:user, email: "sam@acme-sso.dev")
        create(:identity, user: existing_owner, provider: "google_oauth2", uid: "google-uid-1")

        result = described_class.call(auth: auth, current_user: signed_in_user)

        expect(result).to be_success
        expect(result.value).to eq(existing_owner)
        expect(signed_in_user.identities.count).to eq(0)
      end
    end

    context "when a local user already owns the verified email" do
      it "attaches a new identity to that user (no current_user)" do
        local_user = create(:user, email: "sam@acme-sso.dev")

        expect {
          result = described_class.call(auth: auth)
          expect(result).to be_success
          expect(result.value).to eq(local_user)
        }.to change { local_user.identities.count }.by(1)
      end
    end

    context "when no user exists for the email" do
      it "creates a confirmed user + identity and runs the post-confirmation facade", :aggregate_failures do
        allow(Users::PostConfirmationFacade).to receive(:call).and_call_original

        expect {
          result = described_class.call(auth: auth)
          expect(result).to be_success
          expect(result.value).to be_persisted
          expect(result.value.email).to eq("sam@acme-sso.dev")
          expect(result.value).to be_confirmed
          expect(result.value.identities.size).to eq(1)
        }.to change(User, :count).by(1).and change(Identity, :count).by(1)

        expect(Users::PostConfirmationFacade).to have_received(:call).with(user: kind_of(User))
      end

      it "auto-attaches the new SSO user to an org sharing their email domain" do
        org = create(:organisation, slug: "acme-sso-org")
        create(:user, organisation: org, email: "alice@acme-sso.dev")

        result = described_class.call(auth: auth)

        expect(result).to be_success
        expect(result.value.organisation).to eq(org)
        expect(result.value).to be_org_member
      end

      it "propagates a post-confirmation failure as a facade failure" do
        allow(Users::PostConfirmationFacade).to receive(:call).and_return(
          ApplicationFacade::Result.new(success: false, value: nil, error: "boom"),
        )

        result = described_class.call(auth: auth)

        expect(result).to be_failure
        expect(result.error).to eq("boom")
      end
    end

    context "when the provider returns no email" do
      it "fails fast without touching the database" do
        emailless = OmniAuth::AuthHash.new(
          provider: "github",
          uid: "gh-1",
          info: { email: nil, name: "No Email" },
          extra: { raw_info: {} },
        )

        expect {
          result = described_class.call(auth: emailless)
          expect(result).to be_failure
          expect(result.error).to eq(described_class::EMAIL_MISSING_ERROR)
        }.not_to change { [User.count, Identity.count] }
      end
    end
  end
end
