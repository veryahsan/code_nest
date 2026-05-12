# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Projects", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }

  describe "POST /api/v1/projects" do
    it "creates as admin and attaches languages" do
      lang = create(:language)
      expect {
        post "/api/v1/projects",
             params: { project: { name: "Phoenix", language_ids: [ lang.id ] } }.to_json,
             headers: auth_headers_for(admin)
      }.to change(Project, :count).by(1)

      expect(response).to have_http_status(:created)
      project = Project.find_by!(name: "Phoenix")
      expect(project.languages).to include(lang)
    end
  end

  describe "GET /api/v1/projects" do
    before { create(:project, organisation: org, name: "Phoenix") }

    it "lists for members" do
      get "/api/v1/projects", headers: auth_headers_for(member)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"].size).to eq(1)
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    let!(:project) { create(:project, organisation: org) }

    it "destroys as admin" do
      expect {
        delete "/api/v1/projects/#{project.id}", headers: auth_headers_for(admin)
      }.to change(Project, :count).by(-1)
    end

    it "denies members" do
      delete "/api/v1/projects/#{project.id}", headers: auth_headers_for(member)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
