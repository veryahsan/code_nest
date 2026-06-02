# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:org)   { create(:organisation) }
  let(:user)  { create(:user, organisation: org) }
  let(:actor) { create(:user, organisation: org) }
  let(:conversation) { create(:conversation, organisation: org) }

  def notify!(recipient: user, read: false)
    message = create(:message, user: actor, conversation: conversation)
    Notification.create!(recipient: recipient, actor: actor, notifiable: message,
                         kind: "message_created", read_at: read ? Time.current : nil)
  end

  describe "GET /notifications" do
    it "redirects guests" do
      get notifications_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists the signed-in user's notifications" do
      notify!
      create(:notification) # someone else's

      sign_in user
      get notifications_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Conversation.participant_label(actor))
    end
  end

  describe "PATCH /notifications/:id/read" do
    it "marks the notification read and redirects to its conversation" do
      notification = notify!
      sign_in user

      patch read_notification_path(notification)

      expect(notification.reload.read?).to be true
      expect(response).to redirect_to(conversation_path(conversation.id))
    end

    it "does not allow reading another user's notification" do
      notification = notify!(recipient: actor)
      sign_in user

      patch read_notification_path(notification)

      expect(response).to have_http_status(:not_found)
      expect(notification.reload.read?).to be false
    end
  end

  describe "PATCH /notifications/read_all" do
    it "marks all of the user's unread notifications read" do
      notify!
      notify!
      sign_in user

      patch read_all_notifications_path

      expect(user.notifications.unread.count).to eq(0)
    end

    it "leaves other users' notifications untouched" do
      mine    = notify!
      theirs  = notify!(recipient: actor)
      sign_in user

      patch read_all_notifications_path

      expect(mine.reload.read?).to be true
      expect(theirs.reload.read?).to be false
    end
  end
end
