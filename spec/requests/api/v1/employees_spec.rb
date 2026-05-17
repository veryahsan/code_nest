# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Employees", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }

  it "lists employees for org members" do
    create(:employee, organisation: org, display_name: "Alice")
    get "/api/v1/employees", headers: auth_headers_for(member)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["data"].first["attributes"]["display_name"]).to eq("Alice")
  end

  it "creates as admin" do
    user = create(:user, organisation: org)
    expect {
      post "/api/v1/employees",
           params: { employee: { user_id: user.id, display_name: "Bob" } }.to_json,
           headers: auth_headers_for(admin)
    }.to change(Employee, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  describe "GET /api/v1/employees (pagination)" do
    before { create(:employee, organisation: org) }

    it_behaves_like "a paginated JSON:API endpoint" do
      let(:path)    { "/api/v1/employees" }
      let(:headers) { auth_headers_for(member) }
    end
  end
end
