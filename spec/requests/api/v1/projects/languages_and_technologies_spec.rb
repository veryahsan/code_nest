# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Projects::Languages & Technologies", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:project) { create(:project, organisation: org) }

  describe "languages" do
    let(:lang) { create(:language) }

    it "attaches a language as admin" do
      expect {
        post "/api/v1/projects/#{project.id}/languages",
             params: { language_id: lang.id }.to_json,
             headers: auth_headers_for(admin)
      }.to change(project.project_languages, :count).by(1)
    end

    it "detaches a language" do
      link = project.project_languages.create!(language: lang)
      expect {
        delete "/api/v1/projects/#{project.id}/languages/#{link.id}", headers: auth_headers_for(admin)
      }.to change(ProjectLanguage, :count).by(-1)
    end
  end

  describe "technologies" do
    let(:tech) { create(:technology) }

    it "attaches a technology as admin" do
      expect {
        post "/api/v1/projects/#{project.id}/technologies",
             params: { technology_id: tech.id }.to_json,
             headers: auth_headers_for(admin)
      }.to change(project.project_technologies, :count).by(1)
    end
  end

  describe "GET /api/v1/projects/:project_id/languages (pagination)" do
    before { project.project_languages.create!(language: create(:language)) }

    it_behaves_like "a paginated JSON:API endpoint" do
      let(:path)    { "/api/v1/projects/#{project.id}/languages" }
      let(:headers) { auth_headers_for(admin) }
    end
  end

  describe "GET /api/v1/projects/:project_id/technologies (pagination)" do
    before { project.project_technologies.create!(technology: create(:technology)) }

    it_behaves_like "a paginated JSON:API endpoint" do
      let(:path)    { "/api/v1/projects/#{project.id}/technologies" }
      let(:headers) { auth_headers_for(admin) }
    end
  end
end
