# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects::Issues", type: :request do
  let(:org)     { create(:organisation) }
  let(:team)    { create(:team, organisation: org) }
  let(:project) { create(:project, organisation: org, team: team) }
  let(:lead)    { create(:user, organisation: org) }
  let(:member)  { create(:user, organisation: org) }

  before do
    create(:team_membership, team: team, user: lead, lead: true)
    create(:team_membership, team: team, user: member)
  end

  describe "GET /projects/:project_id/issues" do
    it "lists issues for team members" do
      issue = create(:issue, project: project, summary: "Fix login")
      sign_in member
      get project_issues_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Fix login")
      expect(response.body).to include(issue.issue_key)
    end
  end

  describe "POST /projects/:project_id/issues" do
    it "lets the team lead create an issue" do
      sign_in lead
      expect {
        post project_issues_path(project), params: {
          issue: { summary: "New bug", issue_type: "bug", status: "pending", priority: "high" },
        }
      }.to change(project.issues, :count).by(1)

      created = project.issues.find_by!(summary: "New bug")
      expect(response).to redirect_to(project_issue_path(project, created))
    end

    it "denies regular team members" do
      sign_in member
      expect {
        post project_issues_path(project), params: {
          issue: { summary: "Blocked", issue_type: "task", status: "pending", priority: "medium" },
        }
      }.not_to change(Issue, :count)
    end
  end

  describe "PATCH /projects/:project_id/issues/:id" do
    let!(:issue) { create(:issue, project: project, summary: "Original") }

    it "lets the team lead update" do
      sign_in lead
      patch project_issue_path(project, issue), params: { issue: { summary: "Updated" } }
      expect(issue.reload.summary).to eq("Updated")
    end

    it "denies regular team members" do
      sign_in member
      patch project_issue_path(project, issue), params: { issue: { summary: "Hacked" } }
      expect(issue.reload.summary).to eq("Original")
    end
  end

  describe "DELETE /projects/:project_id/issues/:id" do
    let!(:issue) { create(:issue, project: project) }

    it "lets the team lead destroy" do
      sign_in lead
      expect { delete project_issue_path(project, issue) }.to change(Issue, :count).by(-1)
    end

    it "denies regular team members" do
      sign_in member
      expect { delete project_issue_path(project, issue) }.not_to change(Issue, :count)
    end
  end

  describe "project show page" do
    it "shows issues and new-issue action for team lead" do
      create(:issue, project: project, summary: "Visible issue")
      sign_in lead
      get project_path(project)
      expect(response.body).to include("Visible issue")
      expect(response.body).to include("New issue")
    end

    it "hides new-issue action for non-lead members" do
      sign_in member
      get project_path(project)
      expect(response.body).not_to include(new_project_issue_path(project))
    end
  end
end
