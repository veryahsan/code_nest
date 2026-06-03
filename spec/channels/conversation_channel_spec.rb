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

  describe "#read" do
    let(:author) { create(:user, organisation: conversation.organisation) }

    before { conversation.add_participant(author) }

    it "advances the participant's read watermark" do
      create(:message, conversation: conversation, user: author)
      stub_connection current_user: member
      subscribe(id: conversation.id)

      participant = conversation.conversation_participants.find_by(user: member)
      expect { perform :read }.to(change { participant.reload.last_read_at })
    end

    it "broadcasts a read receipt for the newest message" do
      message = create(:message, conversation: conversation, user: author)
      stub_connection current_user: member
      subscribe(id: conversation.id)

      expect { perform :read }
        .to have_broadcasted_to(conversation)
        .with(read_receipt: { user_id: member.id, last_message_id: message.id })
    end

    it "does not broadcast when there are no messages" do
      stub_connection current_user: member
      subscribe(id: conversation.id)

      expect { perform :read }.not_to have_broadcasted_to(conversation)
    end
  end
end
