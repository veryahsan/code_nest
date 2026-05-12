# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Organisation", type: :request do
  let(:org) { create(:organisation, name: "Acme") }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }

  describe "GET /api/v1/organisation" do
    it "returns the caller's org" do
      get "/api/v1/organisation", headers: auth_headers_for(member)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "attributes", "name")).to eq("Acme")
    end

    it "401 without token" do
      get "/api/v1/organisation"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/organisation" do
    it "lets admin update" do
      patch "/api/v1/organisation",
            params: { organisation: { name: "Acme Co" } }.to_json,
            headers: auth_headers_for(admin)
      expect(response).to have_http_status(:ok)
      expect(org.reload.name).to eq("Acme Co")
    end

    it "denies members" do
      patch "/api/v1/organisation",
            params: { organisation: { name: "Hacked" } }.to_json,
            headers: auth_headers_for(member)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
