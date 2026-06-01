# frozen_string_literal: true

# Finds (or creates) the 1:1 direct conversation between two users in the
# same organisation. Direct conversations are deduplicated so a pair of
# users always shares a single thread.
module Conversations
  class FindOrCreateDirectService < ApplicationService
    def initialize(user:, other_user:)
      @user = user
      @other_user = other_user
    end

    def call
      return failure("pick someone to message") if @other_user.blank?
      return failure("you cannot message yourself") if @other_user == @user
      unless @user.organisation_id.present? && @user.organisation_id == @other_user.organisation_id
        return failure("you can only message people in your organisation")
      end

      existing = find_existing
      return success(existing) if existing

      conversation = nil
      ActiveRecord::Base.transaction do
        conversation = Conversation.create!(
          organisation_id: @user.organisation_id,
          kind: :direct,
          created_by: @user,
        )
        conversation.conversation_participants.create!(user: @user)
        conversation.conversation_participants.create!(user: @other_user)
      end

      success(conversation)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.to_sentence.presence || "could not start conversation")
    end

    private

    def find_existing
      Conversation.where(kind: :direct)
                  .where(organisation_id: @user.organisation_id)
                  .joins(:conversation_participants)
                  .where(conversation_participants: { user_id: [@user.id, @other_user.id] })
                  .group("conversations.id")
                  .having("COUNT(conversation_participants.id) = 2")
                  .first
    end
  end
end
