# frozen_string_literal: true

require "rails_helper"

RSpec.describe WelcomeMailer, type: :mailer do
  let(:user) { create(:user, email: "newbie@example.com") }
  let(:mail) { described_class.welcome(user) }

  it "addresses the new user" do
    expect(mail.to).to eq([ "newbie@example.com" ])
  end

  it "sets the welcome subject" do
    expect(mail.subject).to eq("Welcome to Code Nest")
  end

  it "greets the user and links to sign in" do
    expect(mail.body.encoded).to include("Welcome to Code Nest")
    expect(mail.body.encoded).to include(Rails.application.routes.url_helpers.new_user_session_path)
  end
end
