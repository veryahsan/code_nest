# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }

  describe "GET /projects" do
    let!(:project) { create(:project, organisation: org, name: "Phoenix") }

    it "redirects guests" do
      get projects_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists projects the member belongs to" do
      create(:project_membership, project: project, user: member)
      sign_in member
      get projects_path
      expect(response.body).to include("Phoenix")
    end

    it "hides projects the member doesn't belong to" do
      create(:project, organisation: org, name: "Hidden")
      create(:project_membership, project: project, user: member)

      sign_in member
      get projects_path
      expect(response.body).to include("Phoenix")
      expect(response.body).not_to include("Hidden")
    end

    it "lists every project in the org for admins" do
      create(:project, organisation: org, name: "Hidden")

      sign_in admin
      get projects_path
      expect(response.body).to include("Phoenix")
      expect(response.body).to include("Hidden")
    end
  end

  describe "POST /projects" do
    it "lets admin create a project" do
      sign_in admin
      lang = create(:language)
      expect {
        post projects_path, params: { project: { name: "Phoenix", language_ids: [ lang.id ] } }
      }.to change(Project, :count).by(1)

      project = Project.find_by!(name: "Phoenix")
      expect(project.languages).to include(lang)
    end

    it "auto-creates the project's group conversation" do
      sign_in admin
      expect {
        post projects_path, params: { project: { name: "Phoenix" } }
      }.to change(Conversation, :count).by(1)

      project = Project.find_by!(name: "Phoenix")
      expect(project.group_conversation.title).to eq("Phoenix")
    end

    it "denies members" do
      sign_in member
      expect {
        post projects_path, params: { project: { name: "Phoenix" } }
      }.not_to change(Project, :count)
    end

    it "re-renders on validation failure" do
      sign_in admin
      post projects_path, params: { project: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /projects/:id" do
    let(:project) { create(:project, organisation: org, name: "Phoenix") }

    it "renders the tabbed show page with the project name and section tabs" do
      create(:project_membership, project: project, user: member)
      sign_in member
      get project_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Phoenix")
      expect(response.body).to include('data-controller="tabs"')
      %w[Overview Issues Members Documents Resources].each do |label|
        expect(response.body).to include(label)
      end
      expect(response.body).to include(member.email)
    end
  end

  describe "PATCH /projects/:id" do
    let(:project) { create(:project, organisation: org, name: "Phoenix") }

    it "lets admin update the name" do
      sign_in admin
      patch project_path(project), params: { project: { name: "Phoenix v2" } }
      expect(project.reload.name).to eq("Phoenix v2")
    end

    it "denies members" do
      sign_in member
      patch project_path(project), params: { project: { name: "Hacked" } }
      expect(project.reload.name).to eq("Phoenix")
    end
  end

  describe "DELETE /projects/:id" do
    let!(:project) { create(:project, organisation: org) }

    it "destroys when admin" do
      sign_in admin
      expect { delete project_path(project) }.to change(Project, :count).by(-1)
    end

    it "denies members" do
      sign_in member
      expect { delete project_path(project) }.not_to change(Project, :count)
    end
  end

  describe "GET /projects (pagination)" do
    before do
      sign_in admin
      11.times { |i| create(:project, organisation: org, name: "Project #{format('%02d', i)}") }
    end

    it "returns 200 on page 2" do
      get projects_path, params: { page: 2 }
      expect(response).to have_http_status(:ok)
    end

    it "renders the pagination nav when there is more than one page" do
      get projects_path
      expect(response.body).to include("aria-label=\"Pagination\"")
    end
  end
end
