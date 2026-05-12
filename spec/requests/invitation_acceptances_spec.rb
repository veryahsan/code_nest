# frozen_string_literal: true

require "rails_helper"

RSpec.describe "InvitationAcceptances", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:invitation) do
    create(:invitation, organisation: org, email: "newbie@example.com",
           invited_by: admin, expires_at: 7.days.from_now)
  end

  describe "GET /invitation_acceptances/:token" do
    it "renders the acceptance form for a valid token" do
      get invitation_acceptance_path(invitation.token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(org.name)
    end

    it "rejects an unknown token" do
      get invitation_acceptance_path("garbage")
      expect(response).to redirect_to(root_path)
    end

    it "rejects an expired invitation" do
      invitation.update_column(:expires_at, 1.hour.ago)
      get invitation_acceptance_path(invitation.token)
      expect(response).to redirect_to(root_path)
    end

    it "rejects an already-accepted invitation" do
      invitation.update!(accepted_at: 1.day.ago)
      get invitation_acceptance_path(invitation.token)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /invitation_acceptances/:token" do
    it "creates a new user with the chosen password and signs them in" do
      invitation # eager
      expect {
        post submit_invitation_acceptance_path(invitation.token),
             params: { invitation_acceptance: { password: "newpass12345" } }
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(dashboard_path)
      expect(invitation.reload).to be_accepted
    end

    it "re-renders when no password is given for a new user" do
      post submit_invitation_acceptance_path(invitation.token),
           params: { invitation_acceptance: { password: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
