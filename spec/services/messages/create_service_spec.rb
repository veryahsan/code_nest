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

  describe "@mentions" do
    let(:org) { conversation.organisation }
    let(:alice) { create(:user, organisation: org) }
    let(:bob)   { create(:user, organisation: org) }

    before do
      create(:employee, user: member, organisation: org, handle: "author")
      create(:employee, user: alice, organisation: org, handle: "alice")
      create(:employee, user: bob, organisation: org, handle: "bob")
      conversation.add_participant(alice)
    end

    it "persists a MessageMention for a mentioned participant" do
      result = described_class.call(conversation: conversation, user: member, body: "hey @alice")

      expect(result).to be_success
      expect(result.value.mentioned_users).to contain_exactly(alice)
    end

    it "ignores a handle that is not a participant" do
      result = described_class.call(conversation: conversation, user: member, body: "hi @bob")

      expect(result.value.mentioned_users).to be_empty
    end

    it "does not mention the author themselves" do
      result = described_class.call(conversation: conversation, user: member, body: "@author @alice")

      expect(result.value.mentioned_users).to contain_exactly(alice)
    end

    it "deduplicates repeated mentions of the same handle" do
      result = described_class.call(conversation: conversation, user: member, body: "@alice @alice hi")

      expect(result.value.message_mentions.count).to eq(1)
    end

    it "does not treat an email local-part as a mention" do
      result = described_class.call(conversation: conversation, user: member, body: "email me at foo@alice")

      expect(result.value.mentioned_users).to be_empty
    end

    it "resolves mentions from rich HTML via the derived plain text" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_html: "<div>hi <strong>@alice</strong></div>",
      )

      expect(result).to be_success
      expect(result.value.body).to eq("hi @alice")
      expect(result.value.mentioned_users).to contain_exactly(alice)
    end
  end

  describe "rich text (body_html)" do
    it "stores sanitized HTML and derives plain text when formatting is present" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_html: "<div><strong>bold</strong> and plain</div>",
      )

      expect(result).to be_success
      message = result.value
      expect(message).to be_rich
      expect(message.body_html).to include("<strong>bold</strong>")
      expect(message.body).to eq("bold and plain")
    end

    it "drops disallowed tags and scripts" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_html: "<div><strong>safe</strong><script>alert(1)</script></div>",
      )

      expect(result.value.body_html).to include("<strong>safe</strong>")
      expect(result.value.body_html).not_to include("script")
      expect(result.value.body_html).not_to include("alert(1)")
    end

    it "stores plain text only when the rich content carries no formatting" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_html: "<div>just text</div>",
      )

      expect(result).to be_success
      expect(result.value).not_to be_rich
      expect(result.value.body_html).to be_nil
      expect(result.value.body).to eq("just text")
    end

    it "rejects rich content that sanitizes to an empty body" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_html: "<div>   </div>",
      )

      expect(result).to be_failure
    end
  end
end
