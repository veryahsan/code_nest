# frozen_string_literal: true

# Real-time pub/sub for a single conversation. A socket only streams a
# conversation once we have verified the connected user is a participant,
# so the Redis-backed broadcast never leaks to non-members. Clients may
# also send messages over the channel via #speak.
class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = find_conversation

    if conversation
      stream_for conversation
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  # data => { "body" => "..." }
  def speak(data)
    conversation = find_conversation
    return if conversation.nil?

    Messages::CreateService.call(
      conversation: conversation,
      user: current_user,
      body: data["body"],
    )
  end

  # Marks the conversation read for the current user and tells everyone else
  # so they can place this reader's avatar under the latest message. Only the
  # latest message's read state matters, so we broadcast just the reader and
  # the message they caught up to.
  def read(_data = {})
    conversation = find_conversation
    return if conversation.nil?

    participant = conversation.conversation_participants.find_by(user: current_user)
    return if participant.nil?

    participant.mark_read!

    last_message_id = conversation.messages.maximum(:id)
    return if last_message_id.nil?

    ConversationChannel.broadcast_to(
      conversation,
      read_receipt: { user_id: current_user.id, last_message_id: last_message_id },
    )
  end

  private

  def find_conversation
    conversation = Conversation.find_by(id: params[:id])
    return nil if conversation.nil?
    return conversation if current_user.super_admin? || conversation.participant?(current_user)

    nil
  end
end
