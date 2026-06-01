# frozen_string_literal: true

require "rails_helper"

# The `/messages` link is the entry point to the conversations index.
RSpec.describe "Messages", type: :request do
  it "redirects guests to sign-in" do
    get messages_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the conversations index for signed-in users" do
    sign_in create(:user)

    get messages_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Messages")
  end

  it "is reachable for org-less users too" do
    sign_in create(:user, :without_organisation)

    get messages_path

    expect(response).to have_http_status(:ok)
  end
end
