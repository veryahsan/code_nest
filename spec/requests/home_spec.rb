# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /", type: :request do
  it "renders the home page successfully" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Code Nest")
  end
end
