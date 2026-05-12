# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Teams::Memberships", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:team) { create(:team, organisation: org) }
  let(:newcomer) { create(:user, organisation: org) }

  it "attaches a member" do
    expect {
      post "/api/v1/teams/#{team.id}/memberships",
           params: { membership: { user_id: newcomer.id } }.to_json,
           headers: auth_headers_for(admin)
    }.to change(team.team_memberships, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  it "rejects users from other orgs" do
    foreign = create(:user, organisation: create(:organisation))
    post "/api/v1/teams/#{team.id}/memberships",
         params: { membership: { user_id: foreign.id } }.to_json,
         headers: auth_headers_for(admin)
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
