# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:recipient).class_name("User") }
    it { is_expected.to belong_to(:actor).class_name("User") }
    it { is_expected.to belong_to(:notifiable) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:kind) }
  end

  describe "scopes" do
    let(:org)          { create(:organisation) }
    let(:user)         { create(:user, organisation: org) }
    let(:actor)        { create(:user, organisation: org) }
    let(:conversation) { create(:conversation, organisation: org) }
    let(:message1)     { create(:message, user: actor, conversation: conversation) }
    let(:message2)     { create(:message, user: actor, conversation: conversation) }

    let!(:unread) do
      Notification.create!(recipient: user, actor: actor, notifiable: message1,
                           kind: "message_created")
    end

    let!(:read) do
      Notification.create!(recipient: user, actor: actor, notifiable: message2,
                           kind: "message_created", read_at: 1.hour.ago)
    end

    it "returns only unread notifications from .unread" do
      expect(Notification.unread).to include(unread)
      expect(Notification.unread).not_to include(read)
    end

    it "returns only read notifications from .read" do
      expect(Notification.read).to include(read)
      expect(Notification.read).not_to include(unread)
    end
  end

  describe "#read? and #mark_read!" do
    let(:org)     { create(:organisation) }
    let(:actor)   { create(:user, organisation: org) }
    let(:user)    { create(:user, organisation: org) }
    let(:message) { create(:message, user: actor, conversation: create(:conversation, organisation: org)) }
    let(:notification) do
      Notification.create!(recipient: user, actor: actor, notifiable: message, kind: "message_created")
    end

    it "is unread by default" do
      expect(notification.read?).to be false
    end

    it "becomes read after mark_read!" do
      notification.mark_read!
      expect(notification.reload.read?).to be true
    end

    it "mark_read! is a no-op when already read" do
      notification.mark_read!
      read_at_first = notification.reload.read_at
      notification.mark_read!
      expect(notification.reload.read_at).to eq(read_at_first)
    end
  end

  describe "uniqueness" do
    let(:org)     { create(:organisation) }
    let(:actor)   { create(:user, organisation: org) }
    let(:user)    { create(:user, organisation: org) }
    let(:message) { create(:message, user: actor, conversation: create(:conversation, organisation: org)) }

    it "prevents duplicate rows for the same recipient / notifiable / kind" do
      Notification.create!(recipient: user, actor: actor, notifiable: message, kind: "message_created")

      expect {
        Notification.create!(recipient: user, actor: actor, notifiable: message, kind: "message_created")
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
