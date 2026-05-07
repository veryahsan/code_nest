# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject(:identity) { build(:identity) }

    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:uid) }

    it "rejects providers outside the allow-list" do
      identity.provider = "facebook"
      expect(identity).not_to be_valid
      expect(identity.errors[:provider]).to be_present
    end

    it "scopes uid uniqueness by provider" do
      create(:identity, provider: "google_oauth2", uid: "abc")
      dup = build(:identity, provider: "google_oauth2", uid: "abc")

      expect(dup).not_to be_valid
      expect(dup.errors[:uid]).to be_present
    end

    it "allows the same uid under a different provider" do
      create(:identity, provider: "google_oauth2", uid: "abc")
      same_uid_other_provider = build(:identity, :github, uid: "abc")

      expect(same_uid_other_provider).to be_valid
    end
  end

  describe "PROVIDERS" do
    it "matches the providers Devise is configured for" do
      expect(described_class::PROVIDERS).to match_array(User.omniauth_providers.map(&:to_s))
    end
  end
end
