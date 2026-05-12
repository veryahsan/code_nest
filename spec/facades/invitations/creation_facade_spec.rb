# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitations::CreationFacade, type: :facade do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }

  it "creates a pending invitation and enqueues the mailer" do
    result = described_class.call(
      organisation: org,
      inviter: admin,
      attributes: { email: "newbie@example.com", org_role: "member" },
    )

    expect(result).to be_success
    expect(result.value).to be_persisted
    expect(result.value.token).to be_present
    expect(result.value.expires_at).to be_within(1.minute).of(14.days.from_now)

    expect(Sidekiq::Worker.jobs.size).to be >= 1
  end

  it "fails for an invalid email" do
    result = described_class.call(
      organisation: org,
      inviter: admin,
      attributes: { email: "not-an-email", org_role: "member" },
    )
    expect(result).to be_failure
    expect(result.error.errors[:email]).to be_present
  end

  it "rejects a duplicate pending invitation for the same email" do
    create(:invitation, organisation: org, email: "dup@example.com", invited_by: admin)
    result = described_class.call(
      organisation: org,
      inviter: admin,
      attributes: { email: "dup@example.com", org_role: "member" },
    )
    expect(result).to be_failure
  end
end
