# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Technologies", type: :request do
  let(:org) { create(:organisation) }
  let(:member) { create(:user, organisation: org) }

  describe "GET /api/v1/technologies" do
    before { create(:technology) }

    it "lists technologies for authenticated callers" do
      get "/api/v1/technologies", headers: auth_headers_for(member)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]).not_to be_empty
    end

    it "rejects unauthenticated calls" do
      get "/api/v1/technologies"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/technologies (pagination)" do
    before { create(:technology) }

    it_behaves_like "a paginated JSON:API endpoint" do
      let(:path)    { "/api/v1/technologies" }
      let(:headers) { auth_headers_for(member) }
    end
  end
end
