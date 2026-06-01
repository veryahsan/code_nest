# frozen_string_literal: true

require "rails_helper"

RSpec.describe Messages::CreateService, type: :service do
  let(:conversation) { create(:conversation) }
  let(:member) { create(:user, organisation: conversation.organisation) }

  before { conversation.add_participant(member) }

  it "persists a message for a participant" do
    result = described_class.call(conversation: conversation, user: member, body: "Hello")

    expect(result).to be_success
    expect(result.value.body).to eq("Hello")
  end

  it "rejects a non-participant" do
    outsider = create(:user, organisation: conversation.organisation)
    result = described_class.call(conversation: conversation, user: outsider, body: "Hi")

    expect(result).to be_failure
  end

  it "rejects a blank body" do
    result = described_class.call(conversation: conversation, user: member, body: "  ")
    expect(result).to be_failure
  end
end
