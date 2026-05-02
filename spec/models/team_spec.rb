# frozen_string_literal: true

require "rails_helper"

RSpec.describe Team, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:organisation) }
    it { is_expected.to have_many(:team_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:team_memberships) }
    it { is_expected.to have_many(:projects).dependent(:nullify) }
  end

  describe "validations" do
    subject { build(:team) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:organisation_id).case_insensitive }

    it "normalizes slug" do
      team = build(:team, slug: "  Hello World ")
      team.valid?
      expect(team.slug).to eq("hello-world")
    end
  end
end
