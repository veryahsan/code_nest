# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::DeliverJob, type: :job do
  let(:org)          { create(:organisation) }
  let(:sender)       { create(:user, organisation: org) }
  let(:recipient)    { create(:user, organisation: org) }
  let(:conversation) { create(:conversation, organisation: org) }
  let(:message)      { create(:message, conversation: conversation, user: sender) }

  before do
    conversation.add_participant(sender)
    conversation.add_participant(recipient)
    allow(NotificationsChannel).to receive(:broadcast_to)
  end

  def deliver
    described_class.new.perform(message_id: message.id, recipient_id: recipient.id)
  end

  it "is routed to the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "creates a Notification row for the recipient" do
    expect { deliver }.to change(Notification, :count).by(1)

    notification = Notification.last
    expect(notification.recipient).to eq(recipient)
    expect(notification.actor).to eq(sender)
    expect(notification.notifiable).to eq(message)
    expect(notification.kind).to eq("message_created")
    expect(notification.read_at).to be_nil
  end

  it "broadcasts to the recipient's NotificationsChannel stream" do
    deliver

    expect(NotificationsChannel).to have_received(:broadcast_to).with(
      recipient,
      hash_including(
        kind:            "message_created",
        actor_id:        sender.id,
        message_id:      message.id,
        conversation_id: conversation.id
      )
    )
  end

  it "is idempotent — re-running does not create duplicate notification rows" do
    2.times { deliver }

    expect(Notification.where(recipient: recipient, notifiable: message).count).to eq(1)
  end

  it "no-ops when the message no longer exists" do
    message_id = message.id
    message.destroy!

    expect {
      described_class.new.perform(message_id: message_id, recipient_id: recipient.id)
    }.not_to change(Notification, :count)
    expect(NotificationsChannel).not_to have_received(:broadcast_to)
  end

  it "no-ops when the recipient no longer exists" do
    recipient_id = recipient.id
    recipient.destroy!

    expect {
      described_class.new.perform(message_id: message.id, recipient_id: recipient_id)
    }.not_to change(Notification, :count)
  end
end
