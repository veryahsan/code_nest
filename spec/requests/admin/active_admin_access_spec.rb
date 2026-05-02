# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ActiveAdmin platform access", type: :request do
  describe "GET /admin/organisations" do
    it "redirects guests to Devise sign-in" do
      get "/admin/organisations"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects organisation users away from admin" do
      sign_in create(:user)

      get "/admin/organisations"
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to access the admin.")
    end

    it "allows platform super admins" do
      sign_in create(:user, :super_admin)

      get "/admin/organisations"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin" do
    it "shows organisations index at the admin root" do
      sign_in create(:user, :super_admin)

      get "/admin"
      expect(response).to have_http_status(:ok)
    end
  end
end
