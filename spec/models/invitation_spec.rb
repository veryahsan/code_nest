# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:organisation) }
    it { is_expected.to belong_to(:invited_by).optional }
  end

  describe "validations" do
    subject { build(:invitation) }

    it { is_expected.to validate_presence_of(:email) }

    it "assigns a token" do
      invitation = create(:invitation)
      expect(invitation.token).to be_present
    end

    it "does not allow two pending invitations for the same email and organisation" do
      org = create(:organisation)
      inviter = create(:user, organisation: org)

      create(:invitation, organisation: org, email: "same@example.com", invited_by: inviter)

      duplicate = build(:invitation, organisation: org, email: "same@example.com", invited_by: inviter)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "allows the same email again after an invitation is accepted" do
      org = create(:organisation)
      inviter = create(:user, organisation: org)

      accepted = create(:invitation, organisation: org, email: "same@example.com", invited_by: inviter)
      accepted.update!(accepted_at: Time.current)

      fresh = build(:invitation, organisation: org, email: "same@example.com", invited_by: inviter)
      expect(fresh).to be_valid
    end

    it "rejects invited_by from another organisation" do
      org_a = create(:organisation)
      org_b = create(:organisation)

      invitation = build(:invitation, organisation: org_a, invited_by: create(:user, organisation: org_b))
      expect(invitation).not_to be_valid
      expect(invitation.errors[:invited_by]).to be_present
    end

    it "allows platform super admins as inviter" do
      org = create(:organisation)

      invitation = build(:invitation, organisation: org, invited_by: create(:user, :super_admin))
      expect(invitation).to be_valid
    end

    it "rejects expires_at in the past on create" do
      invitation = build(:invitation, expires_at: 1.day.ago)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:expires_at]).to be_present
    end
  end

  describe "scopes" do
    it "filters pending and accepted" do
      pending_inv = create(:invitation)
      accepted_inv = create(:invitation, accepted_at: Time.current)

      expect(described_class.pending).to include(pending_inv)
      expect(described_class.pending).not_to include(accepted_inv)
      expect(described_class.accepted).to include(accepted_inv)
    end
  end
end
