# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teams::Memberships", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }
  let(:team) { create(:team, organisation: org) }
  let(:newcomer) { create(:user, organisation: org) }

  describe "POST /teams/:team_id/memberships" do
    it "lets an admin add an org member" do
      sign_in admin
      expect {
        post team_memberships_path(team), params: { user_id: newcomer.id }
      }.to change(team.team_memberships, :count).by(1)
      expect(response).to redirect_to(team_path(team))
    end

    it "rejects users from other organisations" do
      foreign = create(:user, organisation: create(:organisation))
      sign_in admin
      expect {
        post team_memberships_path(team), params: { user_id: foreign.id }
      }.not_to change(TeamMembership, :count)
    end

    it "denies non-admins" do
      sign_in member
      expect {
        post team_memberships_path(team), params: { user_id: newcomer.id }
      }.not_to change(TeamMembership, :count)
    end
  end

  describe "DELETE /teams/:team_id/memberships/:id" do
    let!(:membership) { create(:team_membership, team: team, user: newcomer) }

    it "lets an admin remove a member" do
      sign_in admin
      expect {
        delete team_membership_path(team, membership)
      }.to change(TeamMembership, :count).by(-1)
    end

    it "denies non-admins" do
      sign_in member
      expect {
        delete team_membership_path(team, membership)
      }.not_to change(TeamMembership, :count)
    end
  end
end
