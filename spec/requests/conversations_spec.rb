# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversations", type: :request do
  let(:org) { create(:organisation) }
  let(:user) { create(:user, organisation: org) }
  let(:other) { create(:user, organisation: org) }

  describe "GET /conversations" do
    it "redirects guests" do
      get conversations_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists the signed-in user's conversations" do
      conversation = create(:conversation, organisation: org, title: "Roadmap")
      conversation.add_participant(user)
      other_conversation = create(:conversation, organisation: org, title: "Secret")

      sign_in user
      get conversations_path
      expect(response.body).to include("Roadmap")
      expect(response.body).not_to include("Secret")
    end
  end

  describe "POST /conversations (direct)" do
    it "creates or finds a direct conversation and redirects to it" do
      sign_in user
      expect {
        post conversations_path, params: { other_user_id: other.id }
      }.to change(Conversation, :count).by(1)

      conversation = Conversation.last
      expect(response).to redirect_to(conversation_path(conversation))
      expect(conversation.participants).to contain_exactly(user, other)
    end
  end

  describe "POST /conversations (group)" do
    it "creates a group conversation" do
      sign_in user
      expect {
        post conversations_path, params: { title: "Launch", user_ids: [ other.id ] }
      }.to change { Conversation.where(kind: :group).count }.by(1)
    end
  end

  describe "GET /conversations/:id" do
    let(:conversation) { create(:conversation, organisation: org) }

    it "shows the conversation to a participant" do
      conversation.add_participant(user)
      create(:message, conversation: conversation, user: user, body: "Hello world")

      sign_in user
      get conversation_path(conversation)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hello world")
    end

    it "denies a non-participant" do
      sign_in user
      get conversation_path(conversation)
      expect(response).to redirect_to(root_path)
    end

    it "renders existing reactions on a message" do
      conversation.add_participant(user)
      message = create(:message, conversation: conversation, user: user, body: "Ship it")
      create(:reaction, user: user, reactable: message, kind: :celebrate)

      sign_in user
      get conversation_path(conversation)

      expect(response.body).to include(Reaction::KIND_EMOJI["celebrate"])
    end

    it "marks the conversation read for the viewer" do
      conversation.add_participant(user)
      create(:message, conversation: conversation, user: user, body: "Hi")

      sign_in user
      get conversation_path(conversation)

      participant = conversation.conversation_participants.find_by(user: user)
      expect(participant.last_read_at).to be_present
    end
  end

  describe "POST /conversations/:id/messages" do
    let(:conversation) { create(:conversation, organisation: org) }

    it "lets a participant post a message" do
      conversation.add_participant(user)
      sign_in user
      expect {
        post conversation_messages_path(conversation), params: { message: { body: "Hey" } }
      }.to change(conversation.messages, :count).by(1)
    end
  end
end
