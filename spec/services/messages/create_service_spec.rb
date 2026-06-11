# frozen_string_literal: true

require "rails_helper"

RSpec.describe Messages::CreateService, type: :service do
  let(:conversation) { create(:conversation) }
  let(:member) { create(:user, organisation: conversation.organisation) }

  before { conversation.add_participant(member) }

  # Builds the Action Text markup Lexxy stores for an @mention: an attachment
  # carrying the employee's signed global id.
  def mention_tag(employee)
    %(<action-text-attachment sgid="#{employee.attachable_sgid}" ) +
      %(content-type="#{Employee::MENTION_CONTENT_TYPE}"></action-text-attachment>)
  end

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
    let!(:author_employee) { create(:employee, user: member, organisation: org, handle: "author") }
    let!(:alice_employee)  { create(:employee, user: alice, organisation: org, handle: "alice") }
    let!(:bob_employee)    { create(:employee, user: bob, organisation: org, handle: "bob") }

    before { conversation.add_participant(alice) }

    it "persists a MessageMention for a mentioned participant" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_text: "<div>hey #{mention_tag(alice_employee)}</div>",
      )

      expect(result).to be_success
      expect(result.value.mentioned_users).to contain_exactly(alice)
    end

    it "derives the plain-text body from the mention attachment" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_text: "<div>hey #{mention_tag(alice_employee)}</div>",
      )

      expect(result.value.body).to include("hey", "@alice")
    end

    it "ignores a mention of someone who is not a participant" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_text: "<div>hi #{mention_tag(bob_employee)}</div>",
      )

      expect(result.value.mentioned_users).to be_empty
    end

    it "does not mention the author themselves" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_text: "<div>#{mention_tag(author_employee)} #{mention_tag(alice_employee)}</div>",
      )

      expect(result.value.mentioned_users).to contain_exactly(alice)
    end

    it "deduplicates repeated mentions of the same employee" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_text: "<div>#{mention_tag(alice_employee)} #{mention_tag(alice_employee)}</div>",
      )

      expect(result.value.message_mentions.count).to eq(1)
    end
  end

  describe "rich text (body_text)" do
    it "stores Action Text content and derives plain text" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_text: "<div><strong>bold</strong> and plain</div>",
      )

      expect(result).to be_success
      message = result.value
      expect(message).to be_rich
      expect(message.body_text.to_plain_text).to include("bold and plain")
      expect(message.body).to eq("bold and plain")
    end

    it "rejects rich content that flattens to an empty body" do
      result = described_class.call(
        conversation: conversation,
        user: member,
        body_text: "<div>   </div>",
      )

      expect(result).to be_failure
    end
  end
end
