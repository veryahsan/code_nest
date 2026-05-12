# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  let(:password) { "Sup3rSecret!" }
  let!(:user) { create(:user, password: password, password_confirmation: password) }

  describe "POST /api/v1/auth/login" do
    it "returns a JWT for valid credentials" do
      post "/api/v1/auth/login", params: { auth: { email: user.email, password: password } }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["token"]).to be_present
      expect(body["data"]["user"]["attributes"]["email"]).to eq(user.email)

      payload = Api::JwtService.decode(body["data"]["token"])
      expect(payload[:sub]).to eq(user.id)
    end

    it "rejects invalid passwords" do
      post "/api/v1/auth/login", params: { auth: { email: user.email, password: "wrong" } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects unconfirmed users" do
      user.update_column(:confirmed_at, nil)
      post "/api/v1/auth/login", params: { auth: { email: user.email, password: password } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 400 if email or password is missing" do
      post "/api/v1/auth/login", params: { auth: { email: "" } }, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "Bearer token guard on protected routes" do
    it "returns 401 without a bearer token" do
      get "/api/v1/users/me"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with a tampered token" do
      get "/api/v1/users/me", headers: { "Authorization" => "Bearer not.a.real.token" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
