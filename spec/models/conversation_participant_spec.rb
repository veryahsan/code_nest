# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConversationParticipant, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:user) }
  end

  describe "uniqueness" do
    it "is unique per [conversation, user]" do
      participant = create(:conversation_participant)
      dup = build(:conversation_participant, conversation: participant.conversation, user: participant.user)
      expect(dup).not_to be_valid
    end
  end

  describe "capacity" do
    it "limits direct conversations to two participants" do
      conversation = create(:conversation, :direct)
      2.times { conversation.add_participant(create(:user, organisation: conversation.organisation)) }

      third = build(:conversation_participant, conversation: conversation,
                    user: create(:user, organisation: conversation.organisation))
      expect(third).not_to be_valid
    end

    it "limits groups to GROUP_CAPACITY participants" do
      conversation = create(:conversation)
      stub_const("Conversation::GROUP_CAPACITY", 1)
      conversation.add_participant(create(:user, organisation: conversation.organisation))

      overflow = build(:conversation_participant, conversation: conversation,
                       user: create(:user, organisation: conversation.organisation))
      expect(overflow).not_to be_valid
    end
  end
end
