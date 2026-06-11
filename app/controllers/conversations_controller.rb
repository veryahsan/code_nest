# frozen_string_literal: true

# Direct messages and group conversations for the signed-in user. Real-time
# delivery is handled by ConversationChannel; these actions cover the
# initial render, history, and conversation creation.
class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_conversation, only: %i[show read destroy]

  def index
    authorize Conversation
    load_conversation_list
  end

  def show
    @messages = @conversation.messages.includes(:user, :reactions).chronological.last(100)
    mark_read
    @readers = ConversationReadReceiptsFacade.new(@conversation, @messages, current_user).readers

    # A Turbo-Frame request (clicking a row in the list) only needs the thread
    # frame. A full-page request (deep link or reload) renders the whole
    # split-pane shell, so the conversation list on the left is never lost.
    @thread_only = turbo_frame_request?
    load_conversation_list unless @thread_only
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

  # Delete a standalone group. Authorised via ConversationPolicy#destroy?
  # (group admin or super_admin); participants and messages cascade via
  # `dependent: :destroy`.
  def destroy
    @conversation.destroy
    redirect_to conversations_path, notice: "Group deleted."
  end

  private

  def load_conversation
    @conversation = Conversation.find(params[:id])
    authorize @conversation
  end

  # Advance the viewer's read watermark (used for sidebar unread counts). Live
  # read receipts are broadcast from ConversationChannel#read instead.
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

  # Data for the left-hand conversation list, shared by the index and the
  # full-page show (so reloading a conversation keeps the list).
  def load_conversation_list
    @conversations = policy_scope(Conversation)
                       .includes(:participants, :conversation_participants, :project)
                       .order(updated_at: :desc)
                       .to_a
    @contacts = contacts
    @last_messages = last_messages_for(@conversations)
  end

  # Most recent message per conversation, keyed by conversation_id, for the
  # list previews. Two queries (max id per conversation, then load those rows
  # with their senders) instead of N+1.
  def last_messages_for(conversations)
    ids = conversations.map(&:id)
    return {} if ids.empty?

    latest_ids = Message.where(conversation_id: ids)
                        .group(:conversation_id)
                        .maximum(:id)
                        .values

    Message.where(id: latest_ids)
           .includes(:user)
           .index_by(&:conversation_id)
  end
end
