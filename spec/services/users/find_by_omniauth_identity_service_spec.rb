# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::FindByOmniauthIdentityService, type: :service do
  describe ".call" do
    it "returns the user that owns a matching (provider, uid)" do
      user = create(:user)
      create(:identity, user: user, provider: "google_oauth2", uid: "g-1")

      result = described_class.call(provider: "google_oauth2", uid: "g-1")

      expect(result).to be_success
      expect(result.value).to eq(user)
    end

    it "returns nil when no identity matches" do
      result = described_class.call(provider: "google_oauth2", uid: "missing")

      expect(result).to be_success
      expect(result.value).to be_nil
    end

    it "scopes the lookup by provider so the same uid under another provider is a miss" do
      create(:identity, provider: "google_oauth2", uid: "shared")

      result = described_class.call(provider: "github", uid: "shared")

      expect(result).to be_success
      expect(result.value).to be_nil
    end

    it "never writes to the database" do
      create(:identity, provider: "google_oauth2", uid: "g-1")

      expect {
        described_class.call(provider: "google_oauth2", uid: "g-1")
        described_class.call(provider: "google_oauth2", uid: "miss")
      }.not_to change { [ User.count, Identity.count ] }
    end
  end
end
