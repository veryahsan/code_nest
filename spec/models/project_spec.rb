# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:organisation) }
    it { is_expected.to have_many(:project_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:project_memberships) }
    it { is_expected.to have_many(:remote_resources).dependent(:destroy) }
    it { is_expected.to have_many(:project_documents).dependent(:destroy) }
    it { is_expected.to have_many(:issues).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_one(:group_conversation).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:project) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:organisation_id).case_insensitive }
  end

  describe "group conversation" do
    it "auto-creates a group conversation named after the project" do
      project = create(:project, name: "Phoenix")

      expect(project.group_conversation).to be_present
      expect(project.group_conversation).to be_group
      expect(project.group_conversation.title).to eq("Phoenix")
      expect(project.group_conversation.organisation_id).to eq(project.organisation_id)
    end
  end

  describe "#lead" do
    it "returns the user flagged as lead" do
      project = create(:project)
      lead = create(:user, organisation: project.organisation)
      create(:user, organisation: project.organisation).tap do |u|
        create(:project_membership, project: project, user: u)
      end
      create(:project_membership, :lead, project: project, user: lead)

      expect(project.lead).to eq(lead)
    end
  end
end
