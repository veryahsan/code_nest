# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemoteResource, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
  end

  describe "validations" do
    subject { build(:remote_resource) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:kind) }

    it "allows blank url" do
      expect(build(:remote_resource, url: nil)).to be_valid
    end

    it "requires http(s) url when present" do
      resource = build(:remote_resource, url: "ftp://example.com")
      expect(resource).not_to be_valid
      expect(resource.errors[:url]).to be_present
    end

    it "encrypts credentials" do
      resource = create(:remote_resource, credentials: "secret-token")
      resource.reload
      expect(resource.credentials).to eq("secret-token")
      expect(resource.credentials_ciphertext).to be_present
    end
  end
end
