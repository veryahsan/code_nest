# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:organisation) }
    it { is_expected.to belong_to(:project).optional }
    it { is_expected.to have_many(:conversation_participants).dependent(:destroy) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
  end

  describe "validations" do
    it "requires a title for groups" do
      conversation = build(:conversation, title: nil)
      expect(conversation).not_to be_valid
      expect(conversation.errors[:title]).to be_present
    end

    it "does not allow a project on a direct conversation" do
      conversation = build(:conversation, :direct, project: create(:project))
      expect(conversation).not_to be_valid
    end
  end

  describe "#add_participant / #remove_participant" do
    it "adds and removes a user idempotently" do
      conversation = create(:conversation)
      user = create(:user, organisation: conversation.organisation)

      conversation.add_participant(user)
      conversation.add_participant(user)
      expect(conversation.participant?(user)).to be true
      expect(conversation.conversation_participants.count).to eq(1)

      conversation.remove_participant(user)
      expect(conversation.participant?(user)).to be false
    end
  end

  describe "#display_title" do
    it "uses the other participant's label for a direct message" do
      conversation = create(:conversation, :direct)
      me = create(:user, organisation: conversation.organisation, email: "me@example.com")
      them = create(:user, organisation: conversation.organisation, email: "them@example.com")
      conversation.add_participant(me)
      conversation.add_participant(them)

      expect(conversation.display_title(me)).to eq("them")
    end
  end
end
