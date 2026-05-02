# frozen_string_literal: true

require "rails_helper"

RSpec.describe Language, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:project_languages).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:projects).through(:project_languages) }
  end

  describe "validations" do
    subject { build(:language) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).case_insensitive }

    it "normalizes code to lowercase" do
      lang = build(:language, code: " Ruby ")
      lang.valid?
      expect(lang.code).to eq("ruby")
    end
  end
end
