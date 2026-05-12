# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Projects::Documents", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:project) { create(:project, organisation: org) }

  it "creates documents for admins" do
    expect {
      post "/api/v1/projects/#{project.id}/documents",
           params: { project_document: { title: "Runbook", url: "https://example.com" } }.to_json,
           headers: auth_headers_for(admin)
    }.to change(project.project_documents, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  it "lists documents" do
    create(:project_document, project: project, title: "Runbook")
    get "/api/v1/projects/#{project.id}/documents", headers: auth_headers_for(admin)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["data"].size).to eq(1)
  end
end
