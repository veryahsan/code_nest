# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects::Documents", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }
  let(:project) { create(:project, organisation: org) }

  describe "GET /projects/:project_id/documents" do
    before { create(:project_document, project: project, title: "Runbook") }

    it "lists for members" do
      sign_in member
      get project_documents_path(project)
      expect(response.body).to include("Runbook")
    end
  end

  describe "POST /projects/:project_id/documents" do
    it "lets admin create a document" do
      sign_in admin
      expect {
        post project_documents_path(project),
             params: { project_document: { title: "Runbook", url: "https://example.com" } }
      }.to change(project.project_documents, :count).by(1)
    end

    it "denies members" do
      sign_in member
      expect {
        post project_documents_path(project), params: { project_document: { title: "x" } }
      }.not_to change(ProjectDocument, :count)
    end

    it "rejects invalid JSON metadata" do
      sign_in admin
      post project_documents_path(project), params: { project_document: { title: "x", metadata: "broken" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /projects/:project_id/documents/:id" do
    let!(:document) { create(:project_document, project: project) }

    it "lets admin delete" do
      sign_in admin
      expect { delete project_document_path(project, document) }.to change(ProjectDocument, :count).by(-1)
    end
  end
end
