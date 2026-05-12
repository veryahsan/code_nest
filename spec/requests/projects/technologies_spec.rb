# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects::Technologies", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }
  let(:project) { create(:project, organisation: org) }
  let(:technology) { create(:technology) }

  describe "POST /projects/:project_id/project_technologies" do
    it "lets admin attach" do
      sign_in admin
      expect {
        post project_project_technologies_path(project), params: { technology_id: technology.id }
      }.to change(project.project_technologies, :count).by(1)
    end

    it "denies members" do
      sign_in member
      expect {
        post project_project_technologies_path(project), params: { technology_id: technology.id }
      }.not_to change(ProjectTechnology, :count)
    end
  end

  describe "DELETE /projects/:project_id/project_technologies/:id" do
    let!(:link) { create(:project_technology, project: project, technology: technology) }

    it "lets admin detach" do
      sign_in admin
      expect { delete project_project_technology_path(project, link) }.to change(ProjectTechnology, :count).by(-1)
    end
  end
end
