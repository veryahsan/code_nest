# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::CreateFromOmniauthService, type: :service do
  describe ".call" do
    it "creates a confirmed user and the first identity inside one transaction", :aggregate_failures do
      expect {
        result = described_class.call(
          email: "founder@brand-new.example",
          provider: "google_oauth2",
          uid: "g-new-1",
          raw_info: { "hd" => "brand-new.example" },
        )

        expect(result).to be_success
        user = result.value
        expect(user).to be_persisted
        expect(user).to be_confirmed
        expect(user.email).to eq("founder@brand-new.example")
        expect(user.identities.size).to eq(1)
        expect(user.identities.first).to have_attributes(
          provider: "google_oauth2",
          uid: "g-new-1",
          email: "founder@brand-new.example",
          raw_info: { "hd" => "brand-new.example" },
        )
      }.to change(User, :count).by(1).and change(Identity, :count).by(1)
    end

    it "rolls back the user when the identity cannot be saved" do
      create(:identity, provider: "google_oauth2", uid: "g-collide-1")

      expect {
        result = described_class.call(
          email: "second@brand-new.example",
          provider: "google_oauth2",
          uid: "g-collide-1",
        )

        expect(result).to be_failure
        expect(result.error).to be_present
      }.not_to change { [User.count, Identity.count] }
    end

    it "returns a failure with validation messages when the email is invalid" do
      result = described_class.call(email: "not-an-email", provider: "github", uid: "gh-bad-1")

      expect(result).to be_failure
      expect(result.error).to match(/email/i)
      expect(User.where(email: "not-an-email")).to be_empty
    end

    it "does not run any post-confirmation orchestration itself" do
      allow(Users::PostConfirmationFacade).to receive(:call)

      described_class.call(
        email: "iso@brand-new.example",
        provider: "github",
        uid: "gh-iso-1",
      )

      expect(Users::PostConfirmationFacade).not_to have_received(:call)
    end
  end
end
