# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  describe "GET /users/auth/google_oauth2/callback" do
    context "with a brand-new visitor" do
      it "creates the user, signs them in, and redirects to /dashboard" do
        mock_omniauth(:google_oauth2,
          uid: "g-new-1",
          email: "founder@brand-new-co.example",
          name: "Founder",
        )

        expect {
          get user_google_oauth2_omniauth_callback_path
        }.to change(User, :count).by(1).and change(Identity, :count).by(1)

        expect(response).to redirect_to(dashboard_path)

        user = User.find_by!(email: "founder@brand-new-co.example")
        expect(user).to be_confirmed
        expect(user.identities.first.provider).to eq("google_oauth2")
      end
    end

    context "when an identity already exists" do
      it "signs the existing user in without creating a duplicate" do
        user = create(:user, email: "returning@acme.example")
        create(:identity, user: user, provider: "google_oauth2", uid: "g-known-1")

        mock_omniauth(:google_oauth2,
          uid: "g-known-1",
          email: "returning@acme.example",
          name: "Returning User",
        )

        users_before = User.count
        identities_before = Identity.count

        get user_google_oauth2_omniauth_callback_path

        expect(User.count).to eq(users_before)
        expect(Identity.count).to eq(identities_before)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "when the OAuth handshake fails" do
      it "redirects back to /login with a flash" do
        mock_omniauth_failure(:google_oauth2)

        get user_google_oauth2_omniauth_callback_path

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(flash[:alert]).to match(/google.*cancelled or failed/i)
      end
    end
  end

  describe "GET /users/auth/github/callback" do
    it "creates and signs in a brand-new GitHub-only user" do
      mock_omniauth(:github,
        uid: "gh-1",
        email: "octocat@github.example",
        name: "Octocat",
      )

      expect {
        get user_github_omniauth_callback_path
      }.to change(User, :count).by(1).and change(Identity, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
      expect(Identity.last.provider).to eq("github")
    end
  end
end
