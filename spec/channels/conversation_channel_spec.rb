# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConversationChannel, type: :channel do
  let(:conversation) { create(:conversation) }
  let(:member) { create(:user, organisation: conversation.organisation) }
  let(:outsider) { create(:user, organisation: conversation.organisation) }

  before { conversation.add_participant(member) }

  it "streams for a participant" do
    stub_connection current_user: member
    subscribe(id: conversation.id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(conversation)
  end

  it "rejects a non-participant" do
    stub_connection current_user: outsider
    subscribe(id: conversation.id)

    expect(subscription).to be_rejected
  end

  it "creates a message via #speak" do
    stub_connection current_user: member
    subscribe(id: conversation.id)

    expect {
      perform :speak, "body" => "Hi team"
    }.to change(conversation.messages, :count).by(1)
  end
end
