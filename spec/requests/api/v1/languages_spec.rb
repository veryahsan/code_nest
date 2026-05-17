# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Languages", type: :request do
  let(:org) { create(:organisation) }
  let(:member) { create(:user, organisation: org) }

  describe "GET /api/v1/languages" do
    before { create(:language) }

    it "lists languages for authenticated callers" do
      get "/api/v1/languages", headers: auth_headers_for(member)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]).not_to be_empty
    end

    it "rejects unauthenticated calls" do
      get "/api/v1/languages"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/languages (pagination)" do
    before { create(:language) }

    it_behaves_like "a paginated JSON:API endpoint" do
      let(:path)    { "/api/v1/languages" }
      let(:headers) { auth_headers_for(member) }
    end
  end
end
