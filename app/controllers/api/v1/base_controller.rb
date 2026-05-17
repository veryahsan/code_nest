# frozen_string_literal: true

# Base for every /api/v1/* controller. Pulls in JSON:API-shaped error
# rendering, JWT-based auth, and Pundit so the API surface mirrors the
# Hotwire surface's authorisation rules.
module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization
      include Api::V1::ErrorRendering
      # ActionController::API does NOT inherit Pagy::Method from
      # ApplicationController, so it must be included separately for `pagy(...)`
      # to be available in API actions.
      include Pagy::Method

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

      # JSON:API-style metadata block for paginated index endpoints.
      def pagy_meta(pagy)
        {
          current_page: pagy.page,
          per_page:     pagy.limit,
          total_pages:  pagy.last,
          total_count:  pagy.count
        }
      end

      # JSON:API-style links block for paginated index endpoints. Keys with a
      # nil URL (e.g. no `next` on the last page) are omitted via `.compact`.
      def pagy_links(pagy)
        {
          self:  pagy.page_url(:current),
          first: pagy.page_url(:first),
          prev:  pagy.page_url(:previous),
          next:  pagy.page_url(:next),
          last:  pagy.page_url(:last)
        }.compact
      end
    end
  end
end
