# frozen_string_literal: true

# No-JS fallback for sending and listing messages. When Action Cable is
# available the Stimulus controller sends over the channel instead, but
# posting the form still works without JavaScript.
module Conversations
  class MessagesController < ApplicationController
    before_action :authenticate_user!
    before_action :load_conversation

    def index
      messages = @conversation.messages.includes(:user).chronological.last(100)
      render json: messages.map(&:broadcast_payload)
    end

    def create
      result = ::Messages::CreateService.call(
        conversation: @conversation,
        user: current_user,
        body: params.dig(:message, :body),
      )

      respond_to do |format|
        format.html do
          if result.success?
            redirect_to conversation_path(@conversation)
          else
            redirect_to conversation_path(@conversation), alert: result.error
          end
        end
        format.json do
          if result.success?
            render json: result.value.broadcast_payload, status: :created
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
      end
    end

    private

    def load_conversation
      @conversation = Conversation.find(params[:conversation_id])
      authorize @conversation, :show?
    end
  end
end
