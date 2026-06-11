# frozen_string_literal: true

# Persists a message authored by a participant of a conversation. The
# broadcast to subscribers is handled by the Message model's
# after_create_commit hook, so both HTTP and Action Cable paths fan out
# identically.
#
# Rich messages are authored in the Lexxy editor and stored as Action Text in
# `body_text` (Action Text sanitizes the markup and preserves mention
# attachments). The canonical plain text in `body` is derived from that rich
# content and is what notification previews and search read.
#
# @mentions arrive as Action Text attachments carrying each mentioned user's
# signed global id, so the mentioned users are read straight off the resolved
# attachables (no handle re-parsing) and persisted as MessageMention rows inside
# the same transaction as the message.
module Messages
  class CreateService < ApplicationService
    def initialize(conversation:, user:, body: nil, body_text: nil)
      @conversation = conversation
      @user = user
      @body = body
      @body_text = body_text
    end

    def call
      unless @conversation.participant?(@user)
        return failure("you are not a participant of this conversation")
      end

      message = @conversation.messages.new(user: @user)
      assign_body(message)

      saved = Message.transaction do
        next false unless message.save

        persist_mentions(message)
        true
      end

      if saved
        success(message)
      else
        failure(message.errors.full_messages.to_sentence.presence || "could not send message")
      end
    end

    private

    # Rich (Lexxy) input is stored in Action Text; `body` is then derived from
    # its plain-text rendering so the two stay in sync. A plain-text-only input
    # (the JSON API / legacy path) just sets `body`.
    def assign_body(message)
      if @body_text.present?
        message.body_text = @body_text
        message.body = message.body_text.to_plain_text.to_s.strip
      else
        message.body = @body.to_s.strip
      end
    end

    # Mentioned users come from the resolved mention attachments, filtered to
    # this conversation's participants and excluding the author (you don't get
    # notified for mentioning yourself).
    def persist_mentions(message)
      return if message.body_text.body.blank?

      mentioned_user_ids = message.body_text.body.attachables.grep(User).map(&:id).uniq
      return if mentioned_user_ids.empty?

      user_ids = @conversation.participants
                              .where(id: mentioned_user_ids)
                              .where.not(id: message.user_id)
                              .pluck(:id)
      return if user_ids.empty?

      now = Time.current
      rows = user_ids.map do |uid|
        { message_id: message.id, mentioned_user_id: uid, created_at: now }
      end
      MessageMention.insert_all(rows)
    end
  end
end
