# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectDocument, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
  end

  describe "validations" do
    subject { build(:project_document) }

    it { is_expected.to validate_presence_of(:title) }

    it "requires http(s) url when present" do
      doc = build(:project_document, url: "javascript:alert(1)")
      expect(doc).not_to be_valid
      expect(doc.errors[:url]).to be_present
    end
  end
end
