# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Turbo frame navigation", type: :request do
  let(:org) { create(:organisation) }
  let(:member) { create(:user, organisation: org) }

  before { sign_in member }

  describe "GET /employees" do
    it "renders full chrome on a normal request" do
      get employees_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="sidebar-panel"')
      expect(response.body).to include(%(id="#{ApplicationHelper::MAIN_CONTENT_FRAME}"))
    end

    it "renders only the main frame without sidebar on Turbo-Frame requests" do
      get employees_path, headers: { "Turbo-Frame" => ApplicationHelper::MAIN_CONTENT_FRAME }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="#{ApplicationHelper::MAIN_CONTENT_FRAME}"))
      expect(response.body).not_to include('id="sidebar-panel"')
    end
  end
end
