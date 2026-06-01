# frozen_string_literal: true

# Direct messages and group conversations for the signed-in user. Real-time
# delivery is handled by ConversationChannel; these actions cover the
# initial render, history, and conversation creation.
class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_conversation, only: %i[show read]

  def index
    @conversations = policy_scope(Conversation)
                       .includes(:participants, :conversation_participants, :project)
                       .order(updated_at: :desc)
    authorize Conversation
    @contacts = contacts
  end

  def show
    @messages = @conversation.messages.includes(:user).chronological.last(100)
    mark_read
    @contacts = contacts
  end

  def new
    authorize Conversation
    @contacts = contacts
  end

  def create
    authorize Conversation

    result =
      if params[:other_user_id].present?
        Conversations::FindOrCreateDirectService.call(
          user: current_user,
          other_user: current_organisation_users.find_by(id: params[:other_user_id]),
        )
      else
        Conversations::CreateGroupService.call(
          creator: current_user,
          title: params[:title],
          user_ids: params[:user_ids],
        )
      end

    if result.success?
      redirect_to conversation_path(result.value)
    else
      redirect_to conversations_path, alert: result.error
    end
  end

  def read
    mark_read
    head :no_content
  end

  private

  def load_conversation
    @conversation = Conversation.find(params[:id])
    authorize @conversation
  end

  def mark_read
    @conversation.conversation_participants.find_by(user: current_user)&.mark_read!
  end

  def current_organisation_users
    return User.none if current_user.organisation_id.blank?

    current_user.organisation.users
  end

  # People the user can start a direct message with.
  def contacts
    current_organisation_users.where.not(id: current_user.id).order(:email)
  end
end
