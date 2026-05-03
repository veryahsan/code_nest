# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Confirmations", type: :request do
  let(:organisation) { create(:organisation) }
  let!(:user) do
    User.create!(
      email: "pending@example.com",
      password: "password12345",
      password_confirmation: "password12345",
      organisation: organisation,
    )
  end

  before { ActionMailer::Base.deliveries.clear }

  describe "GET /verify (confirm via emailed token)" do
    it "confirms the account and redirects to sign-in" do
      raw_token, hashed = Devise.token_generator.generate(User, :confirmation_token)
      user.update_columns(confirmation_token: hashed, confirmation_sent_at: Time.current)

      get user_confirmation_path(confirmation_token: raw_token)

      expect(user.reload.confirmed?).to be true
      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!
      expect(flash[:notice]).to match(/successfully confirmed/i)
    end

    it "rejects an invalid token without confirming the user" do
      get user_confirmation_path(confirmation_token: "definitely-not-a-real-token")

      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:ok)
      expect(user.reload.confirmed?).to be false
      expect(response.body).to match(/invalid|not found/i)
    end

    it "rejects an expired token" do
      raw_token, hashed = Devise.token_generator.generate(User, :confirmation_token)
      user.update_columns(
        confirmation_token: hashed,
        confirmation_sent_at: (Devise.confirm_within + 1.day).ago,
      )

      get user_confirmation_path(confirmation_token: raw_token)

      expect(user.reload.confirmed?).to be false
      expect(response.body).to match(/expired|request a new one/i)
    end

    it "auto-attaches the user to an existing tenant when the email domain already exists" do
      acme = create(:organisation, name: "Acme Confirms", slug: "acme-confirms")
      create(:user, organisation: acme, email: "alice@acme-confirms.dev")

      newcomer = User.create!(
        email: "bob@acme-confirms.dev",
        password: "password12345",
        password_confirmation: "password12345",
      )
      raw_token, hashed = Devise.token_generator.generate(User, :confirmation_token)
      newcomer.update_columns(confirmation_token: hashed, confirmation_sent_at: Time.current)

      get user_confirmation_path(confirmation_token: raw_token)

      expect(newcomer.reload.organisation).to eq(acme)
      expect(newcomer).to be_org_member
    end

    it "leaves the user org-less when no existing user shares the email domain" do
      newcomer = User.create!(
        email: "founder@empty-domain.example",
        password: "password12345",
        password_confirmation: "password12345",
      )
      raw_token, hashed = Devise.token_generator.generate(User, :confirmation_token)
      newcomer.update_columns(confirmation_token: hashed, confirmation_sent_at: Time.current)

      get user_confirmation_path(confirmation_token: raw_token)

      expect(newcomer.reload.organisation).to be_nil
    end
  end

  describe "POST /verify (resend instructions)" do
    it "delivers a fresh confirmation email" do
      expect {
        post user_confirmation_path, params: { user: { email: user.email } }
      }.to change(ActionMailer::Base.deliveries, :size).by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to match(/confirmation/i)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not deliver a second email when the account is already confirmed" do
      user.confirm

      expect {
        post user_confirmation_path, params: { user: { email: user.email } }
      }.not_to change(ActionMailer::Base.deliveries, :size)
    end
  end
end
