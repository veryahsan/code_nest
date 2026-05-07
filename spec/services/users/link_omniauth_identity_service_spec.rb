# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::LinkOmniauthIdentityService, type: :service do
  let(:user) { create(:user) }

  describe ".call" do
    it "creates a new Identity attached to the supplied user and returns success(user)" do
      expect {
        result = described_class.call(
          user: user,
          provider: "google_oauth2",
          uid: "g-link-1",
          email: "sam@acme.example",
          raw_info: { "hd" => "acme.example" },
        )

        expect(result).to be_success
        expect(result.value).to eq(user)
      }.to change { user.identities.count }.by(1)

      identity = user.identities.last
      expect(identity).to have_attributes(
        provider: "google_oauth2",
        uid: "g-link-1",
        email: "sam@acme.example",
        raw_info: { "hd" => "acme.example" },
      )
    end

    it "defaults email and raw_info when the caller omits them" do
      result = described_class.call(user: user, provider: "github", uid: "gh-1")

      expect(result).to be_success
      identity = user.identities.last
      expect(identity.email).to be_nil
      expect(identity.raw_info).to eq({})
    end

    it "returns a failure when the (provider, uid) is already taken by another user" do
      other_user = create(:user)
      create(:identity, user: other_user, provider: "google_oauth2", uid: "g-dup-1")

      result = described_class.call(user: user, provider: "google_oauth2", uid: "g-dup-1")

      expect(result).to be_failure
      expect(result.error).to be_present
      expect(user.identities.count).to eq(0)
    end

    it "returns a failure with the validation message when the provider is not in the allow-list" do
      result = described_class.call(user: user, provider: "facebook", uid: "fb-1")

      expect(result).to be_failure
      expect(result.error).to match(/provider/i)
    end
  end
end
