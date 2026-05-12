# frozen_string_literal: true

# Base for every /api/v1/* controller. Pulls in JSON:API-shaped error
# rendering, JWT-based auth, and Pundit so the API surface mirrors the
# Hotwire surface's authorisation rules.
module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization
      include Api::V1::ErrorRendering

      before_action :authenticate_api_user!

      attr_reader :current_api_user

      private

      # Devise sessions don't reach the API; we authenticate every request
      # by validating the bearer token. Returns 401 if the header is
      # missing/malformed and the action requires authentication.
      def authenticate_api_user!
        token = bearer_token
        return render_unauthorized!("missing bearer token") if token.blank?

        payload = Api::JwtService.decode(token)
        @current_api_user = User.find_by(id: payload[:sub])
        render_unauthorized!("user not found") if @current_api_user.nil?
      rescue Api::JwtService::DecodeError => e
        render_unauthorized!(e.message)
      end

      def bearer_token
        header = request.headers["Authorization"].to_s
        return nil unless header.start_with?("Bearer ")

        header.split(" ", 2).last
      end

      def current_api_organisation
        current_api_user&.organisation
      end

      def require_api_organisation!
        return if current_api_organisation
        return if current_api_user&.super_admin?

        render_error!(:forbidden, "organisation required to access this resource")
      end

      def pundit_user
        current_api_user
      end
    end
  end
end
