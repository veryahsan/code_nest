# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:organisation) }
    it { is_expected.to belong_to(:team).optional }
    it { is_expected.to have_many(:remote_resources).dependent(:destroy) }
    it { is_expected.to have_many(:project_documents).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:project) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:organisation_id).case_insensitive }

    it "rejects a team from another organisation" do
      org_a = create(:organisation)
      org_b = create(:organisation)
      team = create(:team, organisation: org_b)

      project = build(:project, organisation: org_a, team: team)
      expect(project).not_to be_valid
      expect(project.errors[:team]).to be_present
    end
  end
end
