# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /", type: :request do
  it "renders the home page successfully" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Code Nest")
  end

  it "renders the marketing hero with sign-up and sign-in CTAs" do
    get root_path

    expect(response.body).to include("Your engineering org")
    expect(response.body).to include(new_user_registration_path)
    expect(response.body).to include(new_user_session_path)
  end

  it "renders each marketing section heading" do
    get root_path

    expect(response.body).to include("Built for the way engineering orgs actually work")
    expect(response.body).to include("From sign-up to source of truth in minutes")
    expect(response.body).to include("Built on tools you already trust")
    expect(response.body).to include("Frequently asked questions")
  end

  it "still renders for a signed-in user without an organisation (no redirect)" do
    org_less = create(:user, :without_organisation)
    sign_in org_less

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Your engineering org")
  end

  it "redirects signed-in users with an organisation to the dashboard" do
    user = create(:user)
    sign_in user

    get root_path

    expect(response).to redirect_to(dashboard_path)
  end
end
