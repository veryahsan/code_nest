# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reactions::ToggleService, type: :service do
  let(:conversation) { create(:conversation) }
  let(:member)       { create(:user, organisation: conversation.organisation) }
  let(:message)      { create(:message, conversation: conversation, user: member) }

  before { conversation.add_participant(member) }

  it "adds a reaction on first call" do
    expect {
      result = described_class.call(message: message, user: member, kind: "like")
      expect(result).to be_success
      expect(result.value).to eq(:added)
    }.to change(Reaction, :count).by(1)
  end

  it "removes the reaction on the second call (toggle)" do
    described_class.call(message: message, user: member, kind: "like")

    expect {
      result = described_class.call(message: message, user: member, kind: "like")
      expect(result.value).to eq(:removed)
    }.to change(Reaction, :count).by(-1)
  end

  it "allows different kinds to coexist for the same user" do
    described_class.call(message: message, user: member, kind: "like")

    expect {
      described_class.call(message: message, user: member, kind: "love")
    }.to change(Reaction, :count).by(1)

    expect(message.reactions.pluck(:kind)).to contain_exactly("like", "love")
  end

  it "rejects an invalid kind" do
    result = described_class.call(message: message, user: member, kind: "nope")

    expect(result).to be_failure
    expect(Reaction.count).to eq(0)
  end

  it "rejects a non-participant" do
    outsider = create(:user, organisation: conversation.organisation)

    result = described_class.call(message: message, user: outsider, kind: "like")

    expect(result).to be_failure
    expect(Reaction.count).to eq(0)
  end

  it "broadcasts the change to the conversation" do
    message # create up front so its own creation broadcast is not counted

    expect {
      described_class.call(message: message, user: member, kind: "like")
    }.to have_broadcasted_to(conversation).from_channel(ConversationChannel)
  end
end
