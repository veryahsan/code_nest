# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::EmailRoutes do
  describe ".spec_for" do
    it "routes user.signed_up to the welcome mailer at low priority" do
      user = create(:user)

      spec = described_class.spec_for("user.signed_up", user: user)

      expect(spec).to eq(mailer: WelcomeMailer, action: :welcome, args: [ user ], priority: :low)
    end

    it "skips the welcome email for super admins" do
      user = create(:user, :super_admin)

      expect(described_class.spec_for("user.signed_up", user: user)).to be_nil
    end

    it "routes devise.notification to the Devise mailer at high priority" do
      user = create(:user)

      spec = described_class.spec_for(
        "devise.notification", user: user, notification: "confirmation_instructions", args: [ "tok", {} ]
      )

      expect(spec).to eq(
        mailer: Devise.mailer, action: :confirmation_instructions, args: [ user, "tok", {} ], priority: :high
      )
    end

    it "routes invitation.created to the invite mailer at default priority" do
      invitation = create(:invitation)

      spec = described_class.spec_for("invitation.created", invitation: invitation)

      expect(spec).to eq(mailer: InvitationMailer, action: :invite, args: [ invitation ], priority: :default)
    end

    it "routes invitation.accepted to the accepted mailer at low priority" do
      invitation = create(:invitation)

      spec = described_class.spec_for("invitation.accepted", invitation: invitation)

      expect(spec).to eq(mailer: InvitationMailer, action: :accepted, args: [ invitation ], priority: :low)
    end

    it "skips invitation.accepted when there is no inviter to notify" do
      invitation = create(:invitation, invited_by: nil)

      expect(described_class.spec_for("invitation.accepted", invitation: invitation)).to be_nil
    end

    it "routes project_membership.created to the project membership mailer" do
      membership = create(:project_membership)

      spec = described_class.spec_for("project_membership.created", project_membership: membership)

      expect(spec).to eq(
        mailer: ProjectMembershipMailer, action: :added, args: [ membership ], priority: :default
      )
    end

    it "returns nil for an unregistered event" do
      expect(described_class.spec_for("unknown.event")).to be_nil
    end
  end
end
