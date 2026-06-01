# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::FindOrCreateDirectService, type: :service do
  let(:org) { create(:organisation) }
  let(:user) { create(:user, organisation: org) }
  let(:other) { create(:user, organisation: org) }

  it "creates a direct conversation with both participants" do
    result = described_class.call(user: user, other_user: other)

    expect(result).to be_success
    conversation = result.value
    expect(conversation).to be_direct
    expect(conversation.participants).to contain_exactly(user, other)
  end

  it "deduplicates: returns the same conversation for the same pair" do
    first = described_class.call(user: user, other_user: other).value
    second = described_class.call(user: other, other_user: user).value

    expect(second).to eq(first)
  end

  it "refuses to message yourself" do
    result = described_class.call(user: user, other_user: user)
    expect(result).to be_failure
  end

  it "refuses to message someone in another organisation" do
    foreigner = create(:user, organisation: create(:organisation))
    result = described_class.call(user: user, other_user: foreigner)
    expect(result).to be_failure
  end
end
