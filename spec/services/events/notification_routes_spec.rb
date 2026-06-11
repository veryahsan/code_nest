# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::NotificationRoutes do
  describe ".deliveries_for" do
    describe "message.created" do
      it "notifies every participant except the sender, and mentions additively" do
        org          = create(:organisation)
        sender       = create(:user, organisation: org)
        recipient    = create(:user, organisation: org)
        mentioned    = create(:user, organisation: org)
        conversation = create(:conversation, organisation: org)
        message      = create(:message, conversation: conversation, user: sender)
        conversation.add_participant(sender)
        conversation.add_participant(recipient)
        conversation.add_participant(mentioned)
        create(:message_mention, message: message, mentioned_user: mentioned)

        deliveries = described_class.deliveries_for("message.created", message: message)

        message_created = deliveries.find { |d| d[:kind] == "message_created" }
        user_mentioned  = deliveries.find { |d| d[:kind] == "user_mentioned" }

        expect(message_created[:notifiable]).to eq(message)
        expect(message_created[:actor_id]).to eq(sender.id)
        expect(message_created[:recipient_ids]).to contain_exactly(recipient.id, mentioned.id)

        expect(user_mentioned[:recipient_ids]).to contain_exactly(mentioned.id)
        expect(user_mentioned[:actor_id]).to eq(sender.id)
      end
    end

    describe "invitation.accepted" do
      it "notifies the inviter, with the accepting user as actor" do
        org        = create(:organisation)
        inviter    = create(:user, organisation: org)
        accepter   = create(:user, organisation: org)
        invitation = create(:invitation, organisation: org, invited_by: inviter, email: accepter.email)

        deliveries = described_class.deliveries_for("invitation.accepted", invitation: invitation)

        expect(deliveries.size).to eq(1)
        delivery = deliveries.first
        expect(delivery[:recipient_ids]).to eq([ inviter.id ])
        expect(delivery[:actor_id]).to eq(accepter.id)
        expect(delivery[:notifiable]).to eq(invitation)
        expect(delivery[:kind]).to eq("invitation_accepted")
      end

      it "returns no deliveries when there is no inviter" do
        invitation = create(:invitation, invited_by: nil)

        expect(described_class.deliveries_for("invitation.accepted", invitation: invitation)).to be_empty
      end
    end

    describe "project_membership.created" do
      it "notifies the added user with the project as notifiable and no actor" do
        membership = create(:project_membership)

        deliveries = described_class.deliveries_for("project_membership.created", project_membership: membership)

        expect(deliveries.size).to eq(1)
        delivery = deliveries.first
        expect(delivery[:recipient_ids]).to eq([ membership.user_id ])
        expect(delivery[:actor_id]).to be_nil
        expect(delivery[:notifiable]).to eq(membership.project)
        expect(delivery[:kind]).to eq("project_membership_created")
      end
    end

    it "returns no deliveries for an unregistered event" do
      expect(described_class.deliveries_for("unknown.event")).to eq([])
    end
  end
end
