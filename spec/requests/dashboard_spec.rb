# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisation: organisation) }

  it "redirects guests to sign-in" do
    get dashboard_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the workspace for organisation members" do
    sign_in user
    get dashboard_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(organisation.name)
  end

  it "renders the onboarding CTA for confirmed users without an organisation" do
    org_less = create(:user, :without_organisation)
    sign_in org_less

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Create organisation")
    expect(response.body).to include(new_organisation_path)
  end

  it "redirects platform super admins to Active Admin" do
    sign_in create(:user, :super_admin)
    get dashboard_path
    expect(response).to redirect_to(admin_root_path)
  end
end
