# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organisations::GenerateUniqueSlugService, type: :service do
  describe ".call" do
    it "parameterises a free-form name" do
      result = described_class.call(base_name: "Acme Corp Ltd.")

      expect(result).to be_success
      expect(result.value).to eq("acme-corp-ltd")
    end

    it "appends a numeric suffix when the slug is already taken" do
      create(:organisation, slug: "acme")

      result = described_class.call(base_name: "Acme")

      expect(result.value).to eq("acme-1")
    end

    it "keeps incrementing the suffix until it finds an unused slug" do
      create(:organisation, slug: "acme")
      create(:organisation, slug: "acme-1")

      expect(described_class.call(base_name: "Acme").value).to eq("acme-2")
    end

    it "returns a failure when the name is blank" do
      result = described_class.call(base_name: "")

      expect(result).to be_failure
      expect(result.error).to eq(described_class::BLANK_BASE_ERROR)
    end

    it "returns a failure when the name parameterises to nothing" do
      result = described_class.call(base_name: "!!!")

      expect(result).to be_failure
    end
  end
end
