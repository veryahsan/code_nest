# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::FanoutJob, type: :job do
  include ActiveJob::TestHelper

  let(:org)          { create(:organisation) }
  let(:sender)       { create(:user, organisation: org) }
  let(:recipient)    { create(:user, organisation: org) }
  let(:conversation) { create(:conversation, organisation: org) }
  let(:message)      { create(:message, conversation: conversation, user: sender) }

  before do
    conversation.add_participant(sender)
    conversation.add_participant(recipient)
  end

  it "is routed to the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "enqueues a DeliverJob for each participant except the sender" do
    expect {
      described_class.new.perform(message: message)
    }.to have_enqueued_job(Notifications::DeliverJob)
      .with(message_id: message.id, recipient_id: recipient.id)
      .exactly(:once)
  end

  it "does not enqueue a DeliverJob for the message sender" do
    described_class.new.perform(message: message)

    expect(Notifications::DeliverJob).not_to(
      have_been_enqueued.with(message_id: message.id, recipient_id: sender.id)
    )
  end
end
