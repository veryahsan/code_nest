# frozen_string_literal: true

require "rails_helper"

# Show pages opted into the overlay (via `show_in_modal`) must render inside the
# `modal` Turbo Frame in both situations:
#   - a direct/full load (hard reload, bookmark, typed URL) renders the full
#     signed-in chrome with the modal host already seeded with the overlay, so
#     the page IS the modal rather than a full-page render.
#   - a frame request (a link with data-turbo-frame="modal") renders only the
#     <turbo-frame id="modal"> overlay for Turbo to swap into the host.
RSpec.describe "Modal show layout", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }

  before { sign_in admin }

  shared_examples "an overlay show page" do
    describe "direct/full load" do
      before { get path }

      it "responds successfully" do
        expect(response).to have_http_status(:ok)
      end

      it "seeds the persistent modal host with the overlay" do
        expect(response.body).to include('id="modal"')
        expect(response.body).to include('data-controller="modal-frame"')
        expect(response.body).to include('aria-modal="true"')
        expect(response.body).to include("modal-frame#close")
      end

      it "renders the signed-in chrome behind an empty content area" do
        # The menu capsule (theme toggle) is present…
        expect(response.body).to include('data-action="click->theme#toggle"')
        # …but the main content frame is not (the modal is the page).
        expect(response.body).not_to include(%(id="#{ApplicationHelper::MAIN_CONTENT_FRAME}"))
      end
    end

    describe "Turbo-Frame request" do
      before { get path, headers: { "Turbo-Frame" => "modal" } }

      it "responds successfully" do
        expect(response).to have_http_status(:ok)
      end

      it "renders only the overlay frame, without document chrome" do
        expect(response.body).to include('id="modal"')
        expect(response.body).to include('aria-modal="true"')
        expect(response.body).not_to include("<!DOCTYPE html>")
        expect(response.body).not_to include('data-action="click->theme#toggle"')
      end
    end
  end

  describe "GET /projects/:id" do
    let(:path) { project_path(create(:project, organisation: org)) }

    it_behaves_like "an overlay show page"
  end

  describe "GET /employees/:id" do
    let(:path) { employee_path(create(:employee, organisation: org)) }

    it_behaves_like "an overlay show page"
  end

  describe "GET /projects/:project_id/issues/:id" do
    let(:project) { create(:project, organisation: org) }
    let(:path) { project_issue_path(project, create(:issue, project: project)) }

    it_behaves_like "an overlay show page"
  end

  describe "GET /projects/:project_id/documents/:id" do
    let(:project) { create(:project, organisation: org) }
    let(:path) { project_document_path(project, create(:project_document, project: project)) }

    it_behaves_like "an overlay show page"
  end

  describe "GET /projects/:project_id/remote_resources/:id" do
    let(:project) { create(:project, organisation: org) }
    let(:path) { project_remote_resource_path(project, create(:remote_resource, project: project)) }

    it_behaves_like "an overlay show page"
  end
end
