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
end
