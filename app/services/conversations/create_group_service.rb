# frozen_string_literal: true

# Creates a standalone group conversation owned by its creator. The
# creator is always a participant; additional members must belong to the
# same organisation. Capacity (Conversation::GROUP_CAPACITY) is enforced
# by ConversationParticipant.
module Conversations
  class CreateGroupService < ApplicationService
    def initialize(creator:, title:, user_ids: [])
      @creator = creator
      @title = title.to_s.strip
      @user_ids = Array(user_ids).map(&:to_i).uniq
    end

    def call
      return failure("you need an organisation to start a group") if @creator.organisation_id.blank?
      return failure("give your group a name") if @title.blank?

      members = @creator.organisation.users.where(id: @user_ids).to_a
      conversation = nil

      ActiveRecord::Base.transaction do
        conversation = Conversation.create!(
          organisation_id: @creator.organisation_id,
          kind: :group,
          title: @title,
          created_by: @creator,
        )
        conversation.conversation_participants.create!(user: @creator, admin: true)
        members.each do |member|
          next if member == @creator

          conversation.conversation_participants.create!(user: member)
        end
      end

      success(conversation)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.to_sentence.presence || "could not create group")
    end
  end
end
