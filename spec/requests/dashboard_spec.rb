# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisation: organisation) }

  it "redirects guests to sign-in" do
    get dashboard_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the personal workspace for organisation members" do
    sign_in user
    get dashboard_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Welcome")
    expect(response.body).to include(organisation.name)
  end

  it "scopes the member dashboard to the user's own teams" do
    sign_in user

    my_team    = create(:team, organisation: organisation, name: "Alpha Squad")
    other_team = create(:team, organisation: organisation, name: "Zeta Squad")
    create(:team_membership, team: my_team, user: user)

    get dashboard_path
    expect(response.body).to include("Alpha Squad")
    expect(response.body).not_to include("Zeta Squad")
  end

  it "does not show admin-only analytics or pending-invite signals to a regular member" do
    sign_in user
    get dashboard_path
    expect(response.body).not_to include("Organisation analytics")
    expect(response.body).not_to include("New this week")
    expect(response.body).not_to include("Pending invites")
  end

  it "renders the admin analytics view for organisation admins" do
    admin = create(:user, :organisation_admin, organisation: organisation)
    sign_in admin

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Organisation analytics")
    expect(response.body).to include("New this week")
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
