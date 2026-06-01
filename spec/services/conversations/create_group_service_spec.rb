# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::CreateGroupService, type: :service do
  let(:org) { create(:organisation) }
  let(:creator) { create(:user, organisation: org) }
  let(:alice) { create(:user, organisation: org) }
  let(:bob) { create(:user, organisation: org) }

  it "creates a group with the creator and selected members" do
    result = described_class.call(creator: creator, title: "Launch", user_ids: [ alice.id, bob.id ])

    expect(result).to be_success
    conversation = result.value
    expect(conversation).to be_group
    expect(conversation.title).to eq("Launch")
    expect(conversation.participants).to include(creator, alice, bob)
  end

  it "requires a title" do
    result = described_class.call(creator: creator, title: " ", user_ids: [])
    expect(result).to be_failure
  end

  it "ignores user ids outside the creator's organisation" do
    foreigner = create(:user, organisation: create(:organisation))
    result = described_class.call(creator: creator, title: "Launch", user_ids: [ foreigner.id ])

    expect(result).to be_success
    expect(result.value.participants).to contain_exactly(creator)
  end
end
