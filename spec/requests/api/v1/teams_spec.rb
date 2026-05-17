# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Teams", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }

  describe "GET /api/v1/teams" do
    before { create(:team, organisation: org, name: "Engineering") }

    it "lists teams in the caller's org" do
      get "/api/v1/teams", headers: auth_headers_for(member)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      names = body["data"].map { |t| t["attributes"]["name"] }
      expect(names).to include("Engineering")
    end

    it "rejects unauthenticated calls" do
      get "/api/v1/teams"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/teams" do
    it "creates as admin" do
      expect {
        post "/api/v1/teams",
             params: { team: { name: "Eng" } }.to_json,
             headers: auth_headers_for(admin)
      }.to change(org.teams, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "denies members" do
      post "/api/v1/teams",
           params: { team: { name: "Eng" } }.to_json,
           headers: auth_headers_for(member)
      expect(response).to have_http_status(:forbidden)
    end

    it "renders validation errors" do
      post "/api/v1/teams",
           params: { team: { name: "" } }.to_json,
           headers: auth_headers_for(admin)
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to be_present
    end
  end

  describe "PATCH /api/v1/teams/:id" do
    let(:team) { create(:team, organisation: org, name: "X") }

    it "updates as admin" do
      patch "/api/v1/teams/#{team.id}",
            params: { team: { name: "Y" } }.to_json,
            headers: auth_headers_for(admin)
      expect(response).to have_http_status(:ok)
      expect(team.reload.name).to eq("Y")
    end
  end

  describe "DELETE /api/v1/teams/:id" do
    let!(:team) { create(:team, organisation: org) }

    it "destroys as admin" do
      expect {
        delete "/api/v1/teams/#{team.id}", headers: auth_headers_for(admin)
      }.to change(Team, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/v1/teams (pagination)" do
    before { create(:team, organisation: org) }

    it_behaves_like "a paginated JSON:API endpoint" do
      let(:path)    { "/api/v1/teams" }
      let(:headers) { auth_headers_for(member) }
    end
  end
end
