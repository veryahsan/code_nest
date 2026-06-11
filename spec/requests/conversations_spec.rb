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

    it "renders rows that load the thread into the conversation_panel frame" do
      conversation = create(:conversation, organisation: org, title: "Roadmap")
      conversation.add_participant(user)

      sign_in user
      get conversations_path

      expect(response.body).to include('id="conversation_panel"')
      expect(response.body).to include('data-turbo-frame="conversation_panel"')
    end

    it "shows the latest message as a preview in each row" do
      conversation = create(:conversation, organisation: org, title: "Roadmap")
      conversation.add_participant(user)
      create(:message, conversation: conversation, user: other, body: "Latest line")

      sign_in user
      get conversations_path

      expect(response.body).to include("Latest line")
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

    it "returns the thread inside the conversation_panel frame for a frame request" do
      conversation.add_participant(user)
      create(:message, conversation: conversation, user: user, body: "Hello world")

      sign_in user
      get conversation_path(conversation), headers: { "Turbo-Frame" => "conversation_panel" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="conversation_panel"')
      expect(response.body).to include("Hello world")
    end

    it "renders the conversation list alongside the thread on a full-page load" do
      conversation.add_participant(user)
      create(:message, conversation: conversation, user: user, body: "Hello world")
      other_convo = create(:conversation, organisation: org, title: "Roadmap")
      other_convo.add_participant(user)

      sign_in user
      get conversation_path(conversation)

      expect(response).to have_http_status(:ok)
      # The open thread...
      expect(response.body).to include("Hello world")
      # ...and the left list (another conversation the user belongs to).
      expect(response.body).to include("Roadmap")
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

    it "stores rich Action Text content and derives plain text from body_text" do
      conversation.add_participant(user)
      sign_in user

      post conversation_messages_path(conversation),
           params: { message: { body_text: "<div><strong>bold</strong> hi</div>" } }

      message = conversation.messages.last
      expect(message).to be_rich
      expect(message.body_text.to_plain_text).to include("bold")
      expect(message.body).to eq("bold hi")
    end
  end
end
