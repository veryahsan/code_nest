# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      def me
        render json: UserSerializer.new(current_api_user).serializable_hash, status: :ok
      end
    end
  end
end
