# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects::Languages", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }
  let(:project) { create(:project, organisation: org) }
  let(:language) { create(:language) }

  describe "POST /projects/:project_id/project_languages" do
    it "lets admin attach" do
      sign_in admin
      expect {
        post project_project_languages_path(project), params: { language_id: language.id }
      }.to change(project.project_languages, :count).by(1)
    end

    it "denies members" do
      sign_in member
      expect {
        post project_project_languages_path(project), params: { language_id: language.id }
      }.not_to change(ProjectLanguage, :count)
    end
  end

  describe "DELETE /projects/:project_id/project_languages/:id" do
    let!(:link) { create(:project_language, project: project, language: language) }

    it "lets admin detach" do
      sign_in admin
      expect { delete project_project_language_path(project, link) }.to change(ProjectLanguage, :count).by(-1)
    end
  end
end
