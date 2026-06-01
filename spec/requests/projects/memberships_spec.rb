# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects::Memberships", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }
  let(:project) { create(:project, organisation: org) }

  describe "POST /projects/:project_id/memberships" do
    it "lets an admin add a member and syncs the project group" do
      sign_in admin
      expect {
        post project_memberships_path(project), params: { user_id: member.id }
      }.to change(ProjectMembership, :count).by(1)

      expect(project.group_conversation.participant?(member)).to be true
    end

    it "denies a non-admin member" do
      sign_in member
      expect {
        post project_memberships_path(project), params: { user_id: member.id }
      }.not_to change(ProjectMembership, :count)
    end
  end

  describe "DELETE /projects/:project_id/memberships/:id" do
    it "removes the member and syncs the project group" do
      membership = create(:project_membership, project: project, user: member)
      sign_in admin

      expect {
        delete project_membership_path(project, membership)
      }.to change(ProjectMembership, :count).by(-1)

      expect(project.group_conversation.participant?(member)).to be false
    end
  end

  describe "PATCH /projects/:project_id/memberships/:id/promote_lead" do
    it "promotes a member to lead, demoting the previous lead" do
      old_lead = create(:project_membership, :lead, project: project)
      membership = create(:project_membership, project: project, user: member)
      sign_in admin

      patch promote_lead_project_membership_path(project, membership)

      expect(membership.reload.lead).to be true
      expect(old_lead.reload.lead).to be false
    end
  end
end
