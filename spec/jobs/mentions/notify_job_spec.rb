# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mentions::NotifyJob, type: :job do
  include ActiveJob::TestHelper

  let(:org)          { create(:organisation) }
  let(:sender)       { create(:user, organisation: org) }
  let(:mentioned)    { create(:user, organisation: org) }
  let(:conversation) { create(:conversation, organisation: org) }
  let(:message)      { create(:message, conversation: conversation, user: sender) }

  before do
    conversation.add_participant(sender)
    conversation.add_participant(mentioned)
  end

  it "is routed to the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "enqueues a user_mentioned DeliverJob for each mentioned user" do
    create(:message_mention, message: message, mentioned_user: mentioned)

    expect {
      described_class.new.perform(message: message)
    }.to have_enqueued_job(Notifications::DeliverJob)
      .with(message_id: message.id, recipient_id: mentioned.id, kind: "user_mentioned")
      .exactly(:once)
  end

  it "enqueues nothing when there are no mentions" do
    expect {
      described_class.new.perform(message: message)
    }.not_to have_enqueued_job(Notifications::DeliverJob)
  end
end
