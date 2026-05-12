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

  describe "GET /organisations/:id" do
    let(:org)   { create(:organisation, name: "Acme") }
    let(:admin) { create(:user, :organisation_admin, organisation: org) }
    let(:other) { create(:user, organisation: create(:organisation)) }

    it "redirects guests" do
      get organisation_path(org)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders for members of the same organisation" do
      sign_in admin
      get organisation_path(org)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Acme")
    end

    it "denies users from other organisations" do
      sign_in other
      get organisation_path(org)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH /organisations/:id" do
    let(:org)   { create(:organisation, name: "Acme") }
    let(:admin) { create(:user, :organisation_admin, organisation: org) }
    let(:member) { create(:user, organisation: org) }

    it "lets an org admin change the name" do
      sign_in admin
      patch organisation_path(org), params: { organisation: { name: "Acme Co" } }

      expect(response).to redirect_to(organisation_path(org))
      expect(org.reload.name).to eq("Acme Co")
    end

    it "lets an org admin change the slug" do
      sign_in admin
      patch organisation_path(org), params: { organisation: { slug: "acme-co" } }

      expect(org.reload.slug).to eq("acme-co")
    end

    it "denies regular members" do
      sign_in member
      patch organisation_path(org), params: { organisation: { name: "Hacked" } }
      expect(response).to redirect_to(root_path)
      expect(org.reload.name).to eq("Acme")
    end

    it "re-renders edit on validation failure" do
      sign_in admin
      patch organisation_path(org), params: { organisation: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /organisations/:id" do
    let(:org) { create(:organisation) }
    let(:admin) { create(:user, :organisation_admin, organisation: org) }

    it "destroys an org with only the lone admin" do
      sign_in admin
      expect {
        delete organisation_path(org)
      }.to change(Organisation, :count).by(-1)

      expect(response).to redirect_to(root_path)
    end

    it "refuses when other users still belong to the org" do
      sign_in admin
      create(:user, organisation: org)

      expect {
        delete organisation_path(org)
      }.not_to change(Organisation, :count)

      expect(response).to redirect_to(root_path).or have_http_status(:see_other)
    end
  end
end
