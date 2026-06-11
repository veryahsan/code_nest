# frozen_string_literal: true

# Group-admin management of a conversation's roster. Currently supports
# removing a member from a standalone group; authorisation is delegated to
# ConversationPolicy#remove_member? (group admin or super_admin).
module Conversations
  class ParticipantsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_conversation

    def destroy
      participant = @conversation.conversation_participants.find(params[:id])

      if last_admin?(participant)
        return redirect_to conversation_path(@conversation),
                           alert: "You can't remove the group's only admin. Promote someone else or delete the group."
      end

      participant.destroy
      redirect_to conversation_path(@conversation),
                  notice: "#{Conversation.participant_label(participant.user)} was removed from the group."
    end

    private

    def load_conversation
      @conversation = Conversation.find(params[:conversation_id])
      authorize @conversation, :remove_member?
    end

    # Guard against orphaning the group with no admin left.
    def last_admin?(participant)
      participant.admin? &&
        @conversation.conversation_participants.where(admin: true).count <= 1
    end
  end
end
