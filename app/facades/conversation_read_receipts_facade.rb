# frozen_string_literal: true

# Builds the initial read-receipt state for a rendered conversation. Only the
# latest message carries avatars, so this returns the participants who have
# read that message (their `last_read_at` watermark is at or past it),
# excluding the viewer (you don't see your own marker) and the message's
# author (the sender isn't shown as a reader of their own message).
class ConversationReadReceiptsFacade
  def initialize(conversation, messages, viewer)
    @conversation = conversation
    @messages = messages.to_a
    @viewer = viewer
  end

  # => [#<User ...>, ...]
  def readers
    return [] if @messages.empty?

    last = @messages.max_by(&:created_at)

    @conversation.conversation_participants
                 .where.not(user_id: [ @viewer.id, last.user_id ])
                 .where(last_read_at: last.created_at..)
                 .includes(user: :employee)
                 .map(&:user)
  end
end
