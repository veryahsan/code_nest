# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teams", type: :request do
  let(:org)    { create(:organisation) }
  let(:admin)  { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }
  let(:other)  { create(:user, organisation: create(:organisation)) }

  describe "GET /teams" do
    before { create(:team, organisation: org, name: "Engineering") }

    it "redirects guests" do
      get teams_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects org-less users to dashboard" do
      sign_in create(:user, :without_organisation)
      get teams_path
      expect(response).to redirect_to(dashboard_path)
    end

    it "lists teams for members" do
      sign_in member
      get teams_path
      expect(response.body).to include("Engineering")
    end
  end

  describe "POST /teams" do
    it "lets an org admin create a team" do
      sign_in admin
      expect {
        post teams_path, params: { team: { name: "Engineering" } }
      }.to change(org.teams, :count).by(1)

      team = org.teams.find_by!(name: "Engineering")
      expect(team.slug).to eq("engineering")
      expect(response).to redirect_to(team_path(team))
    end

    it "denies regular members" do
      sign_in member
      expect {
        post teams_path, params: { team: { name: "Engineering" } }
      }.not_to change(Team, :count)
    end

    it "re-renders the form on validation failure" do
      sign_in admin
      post teams_path, params: { team: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /teams/:id" do
    let(:team) { create(:team, organisation: org, name: "Eng") }

    it "shows for members of the same org" do
      sign_in member
      get team_path(team)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Eng")
    end

    it "404s for users in another org" do
      sign_in other
      get team_path(team)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /teams/:id" do
    let(:team) { create(:team, organisation: org, name: "Eng", slug: "eng") }

    it "lets admin update name and slug" do
      sign_in admin
      patch team_path(team), params: { team: { name: "Engineering", slug: "engineering" } }
      team.reload
      expect(team.name).to eq("Engineering")
      expect(team.slug).to eq("engineering")
    end

    it "denies members" do
      sign_in member
      patch team_path(team), params: { team: { name: "Hacked" } }
      expect(team.reload.name).to eq("Eng")
    end
  end

  describe "DELETE /teams/:id" do
    let!(:team) { create(:team, organisation: org) }

    it "destroys when admin" do
      sign_in admin
      expect { delete team_path(team) }.to change(Team, :count).by(-1)
      expect(response).to redirect_to(teams_path)
    end

    it "forbidden for members" do
      sign_in member
      expect { delete team_path(team) }.not_to change(Team, :count)
    end
  end
end
