# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::FanoutJob, type: :job do
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

  it "is routed to the critical queue" do
    expect(described_class.new.queue_name).to eq("critical")
  end

  it "creates a Notification row for each participant except the sender" do
    expect {
      described_class.new.perform(message: message)
    }.to change(Notification, :count).by(1)

    notification = Notification.last
    expect(notification.recipient).to eq(recipient)
    expect(notification.actor).to eq(sender)
    expect(notification.notifiable).to eq(message)
    expect(notification.kind).to eq("message_created")
    expect(notification.read_at).to be_nil
  end

  it "does not create a notification for the message sender" do
    described_class.new.perform(message: message)

    expect(Notification.where(recipient: sender)).to be_empty
  end

  it "broadcasts to each recipient's NotificationsChannel stream" do
    described_class.new.perform(message: message)

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
    2.times { described_class.new.perform(message: message) }

    expect(Notification.where(recipient: recipient, notifiable: message).count).to eq(1)
  end
end
