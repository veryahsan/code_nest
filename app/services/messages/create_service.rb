# frozen_string_literal: true

# Persists a message authored by a participant of a conversation. The
# broadcast to subscribers is handled by the Message model's
# after_create_commit hook, so both HTTP and Action Cable paths fan out
# identically.
module Messages
  class CreateService < ApplicationService
    def initialize(conversation:, user:, body:)
      @conversation = conversation
      @user = user
      @body = body
    end

    def call
      unless @conversation.participant?(@user)
        return failure("you are not a participant of this conversation")
      end

      message = @conversation.messages.new(user: @user, body: @body.to_s.strip)

      if message.save
        success(message)
      else
        failure(message.errors.full_messages.to_sentence.presence || "could not send message")
      end
    end
  end
end
