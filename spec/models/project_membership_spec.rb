# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectMembership, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:project) }
  end

  describe "validations" do
    it "is unique per [user, project]" do
      membership = create(:project_membership)
      dup = build(:project_membership, project: membership.project, user: membership.user)
      expect(dup).not_to be_valid
    end

    it "rejects a user from another organisation" do
      project = create(:project)
      foreign = create(:user, organisation: create(:organisation))
      membership = build(:project_membership, project: project, user: foreign)
      expect(membership).not_to be_valid
      expect(membership.errors[:project]).to be_present
    end

    it "allows at most one lead per project" do
      project = create(:project)
      create(:project_membership, :lead, project: project)
      second = build(:project_membership, :lead, project: project,
                     user: create(:user, organisation: project.organisation))
      expect(second).not_to be_valid
      expect(second.errors[:lead]).to be_present
    end

    it "rejects members beyond the capacity" do
      project = create(:project)
      stub_const("ProjectMembership::GROUP_CAPACITY", 1)
      create(:project_membership, project: project)
      overflow = build(:project_membership, project: project,
                       user: create(:user, organisation: project.organisation))
      expect(overflow).not_to be_valid
    end
  end

  describe "group conversation sync" do
    let(:project) { create(:project) }
    let(:user) { create(:user, organisation: project.organisation) }

    it "adds the user to the project's group conversation on create" do
      create(:project_membership, project: project, user: user)
      expect(project.group_conversation.participant?(user)).to be true
    end

    it "removes the user from the group conversation on destroy" do
      membership = create(:project_membership, project: project, user: user)
      membership.destroy
      expect(project.group_conversation.participant?(user)).to be false
    end
  end
end
