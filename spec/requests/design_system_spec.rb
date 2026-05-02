# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /design-system", type: :request do
  it "renders the design system reference page" do
    get design_system_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Design System")
  end
end
