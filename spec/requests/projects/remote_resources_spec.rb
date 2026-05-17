# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects::RemoteResources", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }
  let(:project) { create(:project, organisation: org) }

  describe "GET /projects/:project_id/remote_resources" do
    before { create(:remote_resource, project: project, name: "GH") }

    it "lists for members" do
      sign_in member
      get project_remote_resources_path(project)
      expect(response.body).to include("GH")
    end
  end

  describe "POST /projects/:project_id/remote_resources" do
    it "lets admin create" do
      sign_in admin
      expect {
        post project_remote_resources_path(project),
             params: { remote_resource: { name: "GH", kind: "api_key", credentials_json: '{"k":"v"}' } }
      }.to change(project.remote_resources, :count).by(1)
    end

    it "denies members" do
      sign_in member
      expect {
        post project_remote_resources_path(project), params: { remote_resource: { name: "x", kind: "y" } }
      }.not_to change(RemoteResource, :count)
    end
  end

  describe "GET /projects/:project_id/remote_resources/:id" do
    let!(:resource) do
      create(:remote_resource, project: project, name: "GH", kind: "api_key").tap do |r|
        r.credentials = '{"token":"abc"}'
        r.save!
      end
    end

    it "shows credentials to admins" do
      sign_in admin
      get project_remote_resource_path(project, resource)
      expect(response.body).to include("token")
    end

    it "hides credentials from members" do
      sign_in member
      get project_remote_resource_path(project, resource)
      expect(response.body).not_to include("\"token\":")
      expect(response.body).to include("Hidden")
    end
  end

  describe "GET /projects/:project_id/remote_resources (pagination)" do
    before do
      sign_in member
      11.times { |i| create(:remote_resource, project: project, name: "Res #{format('%02d', i)}") }
    end

    it "returns 200 on page 2" do
      get project_remote_resources_path(project), params: { page: 2 }
      expect(response).to have_http_status(:ok)
    end

    it "renders the pagination nav when there is more than one page" do
      get project_remote_resources_path(project)
      expect(response.body).to include("aria-label=\"Pagination\"")
    end
  end
end
