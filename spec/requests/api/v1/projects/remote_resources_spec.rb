# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Projects::RemoteResources", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:project) { create(:project, organisation: org) }

  it "creates a resource without leaking credentials in the response" do
    post "/api/v1/projects/#{project.id}/remote_resources",
         params: {
           remote_resource: { name: "GH", kind: "api_key", credentials_json: '{"token":"abc"}' }
         }.to_json,
         headers: auth_headers_for(admin)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body["data"]["attributes"].keys).not_to include("credentials")
    expect(response.body).not_to include("\"abc\"")
  end

  describe "GET /api/v1/projects/:project_id/remote_resources (pagination)" do
    before { create(:remote_resource, project: project) }

    it_behaves_like "a paginated JSON:API endpoint" do
      let(:path)    { "/api/v1/projects/#{project.id}/remote_resources" }
      let(:headers) { auth_headers_for(admin) }
    end
  end
end
