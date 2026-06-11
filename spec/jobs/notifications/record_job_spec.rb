# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::RecordJob, type: :job do
  let(:org)          { create(:organisation) }
  let(:sender)       { create(:user, organisation: org) }
  let(:recipient)    { create(:user, organisation: org) }
  let(:conversation) { create(:conversation, organisation: org) }
  let(:message)      { create(:message, conversation: conversation, user: sender) }

  before { allow(NotificationsChannel).to receive(:broadcast_to) }

  def record(**overrides)
    described_class.new.perform(
      **{
        recipient_id:    recipient.id,
        actor_id:        sender.id,
        notifiable_type: "Message",
        notifiable_id:   message.id,
        kind:            "message_created"
      }.merge(overrides)
    )
  end

  it "is routed to the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "creates a Notification row for the recipient" do
    expect { record }.to change(Notification, :count).by(1)

    expect(Notification.last).to have_attributes(
      recipient: recipient, actor: sender, notifiable: message, kind: "message_created", read_at: nil
    )
  end

  it "broadcasts a generic payload to the recipient's NotificationsChannel stream" do
    record

    expect(NotificationsChannel).to have_received(:broadcast_to).with(
      recipient,
      hash_including(kind: "message_created", actor_id: sender.id, body_preview: message.body.to_s.truncate(120))
    )
  end

  it "is idempotent — re-running does not create duplicate rows" do
    2.times { record }

    expect(Notification.where(recipient: recipient, notifiable: message).count).to eq(1)
  end

  it "supports a nil actor (system notification)" do
    project    = create(:project, organisation: org)
    membership = create(:project_membership, project: project, user: recipient)

    expect {
      described_class.new.perform(
        recipient_id:    recipient.id,
        actor_id:        nil,
        notifiable_type: "Project",
        notifiable_id:   membership.project_id,
        kind:            "project_membership_created"
      )
    }.to change(Notification, :count).by(1)

    notification = Notification.last
    expect(notification.actor).to be_nil
    expect(notification.notifiable).to eq(project)
    expect(NotificationsChannel).to have_received(:broadcast_to).with(
      recipient, hash_including(kind: "project_membership_created", actor_label: nil, body_preview: project.name)
    )
  end

  it "no-ops when the notifiable no longer exists" do
    message_id = message.id
    message.destroy!

    expect {
      described_class.new.perform(
        recipient_id: recipient.id, actor_id: sender.id,
        notifiable_type: "Message", notifiable_id: message_id, kind: "message_created"
      )
    }.not_to change(Notification, :count)
    expect(NotificationsChannel).not_to have_received(:broadcast_to)
  end

  it "no-ops when the recipient no longer exists" do
    recipient_id = recipient.id
    recipient.destroy!

    expect {
      record(recipient_id: recipient_id)
    }.not_to change(Notification, :count)
  end
end
