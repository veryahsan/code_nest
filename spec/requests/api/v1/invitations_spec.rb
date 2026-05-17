# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Invitations", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }

  it "lists for admins" do
    create(:invitation, organisation: org, email: "x@y.com", invited_by: admin)
    get "/api/v1/invitations", headers: auth_headers_for(admin)
    expect(response).to have_http_status(:ok)
  end

  it "creates an invitation as admin" do
    expect {
      post "/api/v1/invitations",
           params: { invitation: { email: "fresh@example.com", org_role: "member" } }.to_json,
           headers: auth_headers_for(admin)
    }.to change(Invitation, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  it "denies members" do
    post "/api/v1/invitations",
         params: { invitation: { email: "x@y.com", org_role: "member" } }.to_json,
         headers: auth_headers_for(member)
    expect(response).to have_http_status(:forbidden)
  end

  describe "POST /api/v1/invitations/accept" do
    let(:invitation) do
      create(:invitation, organisation: org, email: "newbie@example.com",
             invited_by: admin, expires_at: 7.days.from_now)
    end

    it "accepts and returns a JWT" do
      invitation # eager
      expect {
        post "/api/v1/invitations/accept",
             params: { invitation_acceptance: { token: invitation.token, password: "newpass12345" } }.to_json,
             headers: { "Content-Type" => "application/json" }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["token"]).to be_present
    end

    it "rejects garbage tokens" do
      post "/api/v1/invitations/accept",
           params: { invitation_acceptance: { token: "nope", password: "x" } }.to_json,
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/invitations (pagination)" do
    before { create(:invitation, organisation: org, invited_by: admin) }

    it_behaves_like "a paginated JSON:API endpoint" do
      let(:path)    { "/api/v1/invitations" }
      let(:headers) { auth_headers_for(admin) }
    end
  end
end
