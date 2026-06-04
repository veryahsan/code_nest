# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reaction, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:reactable) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:kind) }
  end

  describe "kind enum" do
    it "defines the expected reaction kinds" do
      expect(described_class.kinds).to eq(
        "like" => 0, "love" => 1, "laugh" => 2,
        "celebrate" => 3, "insightful" => 4, "sad" => 5
      )
    end
  end

  describe "uniqueness" do
    let(:org)          { create(:organisation) }
    let(:user)         { create(:user, organisation: org) }
    let(:conversation) { create(:conversation, organisation: org) }
    let(:message)      { create(:message, user: user, conversation: conversation) }

    it "allows the same user to react with different kinds on the same record" do
      create(:reaction, user: user, reactable: message, kind: :like)

      expect {
        create(:reaction, user: user, reactable: message, kind: :love)
      }.to change(described_class, :count).by(1)
    end

    it "rejects a duplicate reaction of the same kind by the same user" do
      create(:reaction, user: user, reactable: message, kind: :like)

      duplicate = build(:reaction, user: user, reactable: message, kind: :like)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "enforces uniqueness at the database level" do
      create(:reaction, user: user, reactable: message, kind: :like)

      expect {
        described_class.new(user: user, reactable: message, kind: :like).save!(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows different users to react with the same kind on the same record" do
      other_user = create(:user, organisation: org)
      create(:reaction, user: user, reactable: message, kind: :like)

      expect {
        create(:reaction, user: other_user, reactable: message, kind: :like)
      }.to change(described_class, :count).by(1)
    end
  end
end
