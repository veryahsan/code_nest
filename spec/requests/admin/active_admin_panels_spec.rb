# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ActiveAdmin panels", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before { sign_in super_admin }

  %w[
    organisations
    users
    teams
    projects
    employees
    invitations
    team_memberships
    project_documents
    remote_resources
    languages
    technologies
    identities
  ].each do |resource|
    it "renders /admin/#{resource}" do
      get "/admin/#{resource}"
      expect(response).to have_http_status(:ok),
        "expected /admin/#{resource} to render OK, got #{response.status}"
    end
  end
end
