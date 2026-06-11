# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(Message::MAX_LENGTH) }
  end

  describe "broadcasting" do
    it "broadcasts to the conversation stream on create" do
      conversation = create(:conversation)
      user = create(:user, organisation: conversation.organisation)
      conversation.add_participant(user)

      expect {
        create(:message, conversation: conversation, user: user, body: "Hi")
      }.to have_broadcasted_to(conversation).from_channel(ConversationChannel)
    end
  end

  describe "#rendered_body_html" do
    let(:conversation) { create(:conversation) }
    let(:author) { create(:user, organisation: conversation.organisation) }

    before { conversation.add_participant(author) }

    it "is nil for a plain-text message" do
      message = create(:message, conversation: conversation, user: author, body: "plain")
      expect(message.rendered_body_html).to be_nil
    end

    it "renders rich content with mentions resolved to the employee partial" do
      mentioned = create(:user, organisation: conversation.organisation)
      employee = create(:employee, user: mentioned, organisation: conversation.organisation, handle: "casey")
      conversation.add_participant(mentioned)

      html = %(<div>hi <action-text-attachment sgid="#{employee.attachable_sgid}" ) +
             %(content-type="#{Employee::MENTION_CONTENT_TYPE}"></action-text-attachment></div>)
      message = Messages::CreateService.call(conversation: conversation, user: author, body_text: html).value

      rendered = message.rendered_body_html
      expect(rendered).to include("mention")
      expect(rendered).to include("@casey")
    end
  end
end
