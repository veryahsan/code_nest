# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Registrations", type: :request do
  before { ActionMailer::Base.deliveries.clear }

  let(:valid_attributes) do
    {
      email: "founder@new-co.example",
      password: "password12345",
      password_confirmation: "password12345"
    }
  end

  describe "POST /register" do
    it "creates an unconfirmed, org-less user without spawning an organisation" do
      organisations_before = Organisation.count

      expect {
        post user_registration_path, params: { user: valid_attributes }
      }.to change(User, :count).by(1)
       .and change(ActionMailer::Base.deliveries, :size).by(1)

      expect(Organisation.count).to eq(organisations_before)

      user = User.find_by!(email: "founder@new-co.example")
      expect(user.confirmed?).to be false
      expect(user.organisation).to be_nil
      expect(user).to be_org_member
    end

    it "redirects to the home page with a confirmation flash and does not sign in" do
      post user_registration_path, params: { user: valid_attributes }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:notice]).to match(/confirmation link/i)
    end

    it "sends the confirmation email to the new user with the right sender and token" do
      post user_registration_path, params: { user: valid_attributes }
      user = User.find_by!(email: "founder@new-co.example")

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "founder@new-co.example" ])
      expect(mail.from).to eq([ Devise.mailer_sender ])
      expect(mail.subject).to match(/confirmation/i)
      expect(mail.body.encoded).to include(user.confirmation_token)
    end

    it "blocks the new account from accessing protected pages until confirmed" do
      post user_registration_path, params: { user: valid_attributes }

      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "the sign-up form" do
    it "no longer asks for an organisation name" do
      get new_user_registration_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("user[organisation_name]")
      expect(response.body).not_to include("organisation_name")
    end
  end
end
