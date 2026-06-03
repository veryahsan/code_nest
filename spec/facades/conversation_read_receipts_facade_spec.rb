# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConversationReadReceiptsFacade, type: :facade do
  let(:org)          { create(:organisation) }
  let(:viewer)       { create(:user, organisation: org) }
  let(:author)       { create(:user, organisation: org) }
  let(:reader)       { create(:user, organisation: org) }
  let(:conversation) { create(:conversation, organisation: org) }

  def readers_for(messages)
    described_class.new(conversation, messages, viewer).readers
  end

  def watermark!(user, time)
    conversation.conversation_participants.find_by(user: user).update!(last_read_at: time)
  end

  before do
    conversation.add_participant(viewer)
    conversation.add_participant(author)
    conversation.add_participant(reader)
  end

  it "includes participants whose watermark has reached the last message" do
    message = create(:message, conversation: conversation, user: author, created_at: 1.minute.ago)
    watermark!(reader, message.created_at + 1.second)

    expect(readers_for([ message ])).to contain_exactly(reader)
  end

  it "excludes the viewer and the last message's author" do
    message = create(:message, conversation: conversation, user: author, created_at: 1.minute.ago)
    watermark!(viewer, Time.current)
    watermark!(author, Time.current)
    watermark!(reader, Time.current)

    expect(readers_for([ message ])).to contain_exactly(reader)
  end

  it "excludes participants whose watermark predates the last message" do
    message = create(:message, conversation: conversation, user: author, created_at: 1.minute.ago)
    watermark!(reader, 5.minutes.ago)

    expect(readers_for([ message ])).to be_empty
  end

  it "ignores participants who have not read anything" do
    message = create(:message, conversation: conversation, user: author)

    expect(readers_for([ message ])).to be_empty
  end

  it "returns an empty array when there are no messages" do
    expect(readers_for([])).to eq([])
  end

  it "keys off the latest message when several are loaded" do
    older = create(:message, conversation: conversation, user: author, created_at: 2.minutes.ago)
    newer = create(:message, conversation: conversation, user: author, created_at: 1.minute.ago)
    watermark!(reader, older.created_at + 1.second)

    expect(readers_for([ older, newer ])).to be_empty
  end
end
