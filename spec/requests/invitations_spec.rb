# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }

  describe "GET /invitations" do
    it "redirects guests" do
      get invitations_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "denies regular members" do
      sign_in member
      get invitations_path
      expect(response).to redirect_to(dashboard_path)
    end

    it "shows for org admins" do
      sign_in admin
      create(:invitation, organisation: org, email: "x@y.com", invited_by: admin)
      get invitations_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("x@y.com")
    end
  end

  describe "POST /invitations" do
    it "creates an invitation as admin" do
      sign_in admin
      expect {
        post invitations_path, params: { invitation: { email: "fresh@example.com", org_role: "member" } }
      }.to change(Invitation, :count).by(1)
      expect(response).to redirect_to(invitations_path)
    end

    it "denies members" do
      sign_in member
      expect {
        post invitations_path, params: { invitation: { email: "x@y.com", org_role: "member" } }
      }.not_to change(Invitation, :count)
    end

    it "re-renders on validation failure" do
      sign_in admin
      post invitations_path, params: { invitation: { email: "", org_role: "member" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /invitations/:id" do
    let!(:invitation) { create(:invitation, organisation: org, invited_by: admin) }

    it "revokes a pending invitation" do
      sign_in admin
      expect { delete invitation_path(invitation) }.to change(Invitation, :count).by(-1)
    end

    it "refuses to revoke an accepted invitation" do
      invitation.update!(accepted_at: 1.day.ago)
      sign_in admin
      expect { delete invitation_path(invitation) }.not_to change(Invitation, :count)
    end
  end
end
