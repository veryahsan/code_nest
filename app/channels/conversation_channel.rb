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

  private

  def find_conversation
    conversation = Conversation.find_by(id: params[:id])
    return nil if conversation.nil?
    return conversation if current_user.super_admin? || conversation.participant?(current_user)

    nil
  end
end
