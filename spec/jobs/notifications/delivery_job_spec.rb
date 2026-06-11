# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::DeliveryJob, type: :job do
  include ActiveJob::TestHelper

  it "is routed to the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "enqueues one RecordJob per recipient for a message event" do
    org          = create(:organisation)
    sender       = create(:user, organisation: org)
    recipient    = create(:user, organisation: org)
    conversation = create(:conversation, organisation: org)
    message      = create(:message, conversation: conversation, user: sender)
    conversation.add_participant(sender)
    conversation.add_participant(recipient)

    expect {
      described_class.new.perform(event: "message.created", message: message)
    }.to have_enqueued_job(Notifications::RecordJob)
      .with(
        recipient_id:    recipient.id,
        actor_id:        sender.id,
        notifiable_type: "Message",
        notifiable_id:   message.id,
        kind:            "message_created"
      )
      .exactly(:once)
  end

  it "does not enqueue a RecordJob for the message sender" do
    org          = create(:organisation)
    sender       = create(:user, organisation: org)
    conversation = create(:conversation, organisation: org)
    message      = create(:message, conversation: conversation, user: sender)
    conversation.add_participant(sender)

    described_class.new.perform(event: "message.created", message: message)

    expect(Notifications::RecordJob).not_to(
      have_been_enqueued.with(hash_including(recipient_id: sender.id))
    )
  end

  it "enqueues a RecordJob for the added user on project_membership.created" do
    membership = create(:project_membership)

    expect {
      described_class.new.perform(event: "project_membership.created", project_membership: membership)
    }.to have_enqueued_job(Notifications::RecordJob)
      .with(
        recipient_id:    membership.user_id,
        actor_id:        nil,
        notifiable_type: "Project",
        notifiable_id:   membership.project_id,
        kind:            "project_membership_created"
      )
      .exactly(:once)
  end

  it "enqueues a RecordJob for the assignee on issue.assigned" do
    project  = create(:project)
    assignee = create(:user, organisation: project.organisation)
    assignor = create(:user, organisation: project.organisation)
    issue    = create(:issue, project: project, assignee: assignee, assignor: assignor)

    expect {
      described_class.new.perform(event: "issue.assigned", issue: issue)
    }.to have_enqueued_job(Notifications::RecordJob)
      .with(
        recipient_id:    assignee.id,
        actor_id:        assignor.id,
        notifiable_type: "Issue",
        notifiable_id:   issue.id,
        kind:            "issue_assigned"
      )
      .exactly(:once)
  end

  it "enqueues nothing for an event without a notification route" do
    user = create(:user)

    expect {
      described_class.new.perform(event: "user.signed_up", user: user)
    }.not_to have_enqueued_job(Notifications::RecordJob)
  end
end
