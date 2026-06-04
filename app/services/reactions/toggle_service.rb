# frozen_string_literal: true

# Toggles a single reaction (one kind) by a user on a message. Persisted
# synchronously, mirroring Messages::CreateService, then the change is
# broadcast to every participant of the conversation over ConversationChannel.
#
# Broadcasting lives here rather than on the (polymorphic) Reaction model so
# the ConversationChannel coupling stays out of a generic model.
module Reactions
  class ToggleService < ApplicationService
    def initialize(message:, user:, kind:)
      @message = message
      @user = user
      @kind = kind.to_s
    end

    def call
      return failure("invalid reaction") unless Reaction.kinds.key?(@kind)

      unless @message.conversation.participant?(@user)
        return failure("you are not a participant of this conversation")
      end

      existing = Reaction.find_by(user: @user, reactable: @message, kind: @kind)
      if existing
        existing.destroy!
        state = :removed
      else
        Reaction.create!(user: @user, reactable: @message, kind: @kind)
        state = :added
      end

      broadcast(state)
      success(state)
    rescue ActiveRecord::RecordNotUnique
      # Lost a create race; the row already exists, so the desired state holds.
      success(:added)
    end

    private

    def broadcast(state)
      count = @message.reactions.where(kind: @kind).count

      ConversationChannel.broadcast_to(@message.conversation, reaction: {
        message_id: @message.id,
        kind:       @kind,
        emoji:      Reaction::KIND_EMOJI[@kind],
        user_id:    @user.id,
        state:      state,
        count:      count,
      })
    end
  end
end
