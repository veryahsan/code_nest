# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organisations", type: :request do
  describe "GET /organisations/new" do
    it "redirects guests to sign-in" do
      get new_organisation_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders the form for confirmed users without an organisation" do
      sign_in create(:user, :without_organisation)
      get new_organisation_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create your organisation")
    end

    it "redirects users who already belong to an organisation back to the dashboard" do
      sign_in create(:user, organisation: create(:organisation))
      get new_organisation_path
      expect(response).to redirect_to(dashboard_path)
    end

    it "redirects super admins back to the dashboard (which sends them to admin)" do
      sign_in create(:user, :super_admin)
      get new_organisation_path
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "POST /organisations" do
    let(:user) { create(:user, :without_organisation) }

    before { sign_in user }

    it "creates the organisation and makes the current user its admin" do
      expect {
        post organisations_path, params: { organisation: { name: "Brand New Co" } }
      }.to change(Organisation, :count).by(1)

      org = Organisation.find_by!(name: "Brand New Co")
      expect(org.slug).to eq("brand-new-co")

      user.reload
      expect(user.organisation).to eq(org)
      expect(user).to be_org_admin
    end

    it "redirects to the dashboard with a welcome flash" do
      post organisations_path, params: { organisation: { name: "Brand New Co" } }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(flash[:notice]).to match(/administrator/i)
    end

    it "re-renders the form with errors when the name is blank" do
      expect {
        post organisations_path, params: { organisation: { name: "" } }
      }.not_to change(Organisation, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match(/can&#39;t be blank|prevented saving/i)
      expect(user.reload.organisation).to be_nil
    end

    it "auto-suffixes the slug when a clashing organisation already exists" do
      create(:organisation, name: "Acme Inc", slug: "acme-inc")

      post organisations_path, params: { organisation: { name: "Acme Inc" } }

      org = Organisation.where(name: "Acme Inc").order(:created_at).last
      expect(org.slug).to eq("acme-inc-1")
      expect(user.reload.organisation).to eq(org)
    end
  end
end
