# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Registrations", type: :request do
  include ActiveJob::TestHelper

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
      drain_email_outbox
      user = User.find_by!(email: "founder@new-co.example")

      mail = ActionMailer::Base.deliveries.find { |m| m.subject =~ /confirmation/i }
      expect(mail.to).to eq([ "founder@new-co.example" ])
      expect(mail.from).to eq([ Devise.mailer_sender ])
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

  describe "GET /edit (profile settings)" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "does not render the email field" do
      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("user[email]")
    end

    it "does not render any password fields" do
      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("user[password]")
      expect(response.body).not_to include("user[password_confirmation]")
      expect(response.body).not_to include("user[current_password]")
    end
  end

  describe "GET /edit with notifications in the sidebar" do
    let(:user) { create(:user) }

    before do
      create(:notification, recipient: user)
      sign_in user
    end

    it "renders the notifications dropdown without a missing-partial error" do
      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /edit (avatar section)" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "renders the avatar file input" do
      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("user[avatar]")
    end
  end

  describe "PATCH /edit (avatar upload)" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "attaches a valid image" do
      file = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/avatar.png"),
        "image/png"
      )

      patch user_registration_path, params: { user: { avatar: file } }

      expect(user.reload.avatar).to be_attached
    end

    it "removes the avatar when remove_avatar is checked" do
      user.avatar.attach(
        io: StringIO.new("fake"),
        filename: "old.jpg",
        content_type: "image/jpeg"
      )

      patch user_registration_path, params: { user: { remove_avatar: "1" } }

      expect(user.reload.avatar).not_to be_attached
    end

    it "re-renders the form with errors when the upload is rejected" do
      rejected = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/not_an_image.txt"),
        "text/plain"
      )

      put user_registration_path, params: { user: { avatar: rejected } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("JPEG, PNG, or WebP")
      expect(user.reload.avatar).not_to be_attached
    end
  end

  describe "PATCH /edit (profile update)" do
    let(:user) { create(:user, email: "old@example.com", password: "password12345") }

    before { sign_in user }

    it "ignores an email change submitted directly to the endpoint" do
      patch user_registration_path, params: { user: { email: "new@example.com" } }

      user.reload
      expect(user.email).to eq("old@example.com")
      expect(user.unconfirmed_email).to be_nil
    end

    it "ignores a password change submitted directly to the endpoint" do
      patch user_registration_path,
            params: { user: { password: "brand-new-secret", password_confirmation: "brand-new-secret" } }

      expect(user.reload.valid_password?("password12345")).to be true
    end
  end
end
