# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitations::AcceptFacade, type: :facade do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:invitation) do
    create(:invitation, organisation: org, email: "newbie@example.com",
           org_role: :member, invited_by: admin, expires_at: 7.days.from_now)
  end

  it "creates a brand-new user, attaches them, and marks the invitation accepted" do
    invitation # eagerly create so the let chain doesn't pollute the count below
    expect {
      result = described_class.call(token: invitation.token, password: "newpass12345")
      expect(result).to be_success
    }.to change(User, :count).by(1)

    user = User.find_by!(email: "newbie@example.com")
    expect(user.organisation).to eq(org)
    expect(user).to be_confirmed
    expect(invitation.reload.accepted_at).to be_present
  end

  it "attaches an existing org-less user without creating a new one" do
    existing = create(:user, :without_organisation, email: "newbie@example.com")
    invitation # ensure invitation exists before count baseline below
    expect {
      result = described_class.call(token: invitation.token, password: "ignored")
      expect(result).to be_success
    }.not_to change(User, :count)

    expect(existing.reload.organisation).to eq(org)
  end

  it "refuses when an existing user is in another organisation" do
    create(:user, organisation: create(:organisation), email: "newbie@example.com")
    result = described_class.call(token: invitation.token)
    expect(result).to be_failure
    expect(result.error).to match(/different organisation/i)
  end

  it "fails for an unknown token" do
    expect(described_class.call(token: "garbage", password: "x")).to be_failure
  end

  it "fails for already-accepted invitations" do
    invitation.update!(accepted_at: 1.day.ago)
    expect(described_class.call(token: invitation.token)).to be_failure
  end

  it "fails for expired invitations" do
    invitation.update_column(:expires_at, 1.hour.ago)
    expect(described_class.call(token: invitation.token)).to be_failure
  end
end
