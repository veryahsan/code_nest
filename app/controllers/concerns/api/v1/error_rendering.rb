# frozen_string_literal: true

# Standardises error responses across every /api/v1/* controller using
# the JSON:API error-object shape:
#
#   { "errors": [{ "status": "404", "title": "Not Found", "detail": "..." }] }
#
# Use #render_error!(status, message) for one-off errors, or rely on the
# rescue_from hooks for ActiveRecord/Pundit exceptions raised from
# anywhere in a request. Field-level validation errors come back with a
# JSON-pointer source so SPA forms can highlight the right input.
module Api
  module V1
    module ErrorRendering
      extend ActiveSupport::Concern

      STATUS_TITLES = {
        bad_request: "Bad Request",
        unauthorized: "Unauthorized",
        forbidden: "Forbidden",
        not_found: "Not Found",
        unprocessable_entity: "Unprocessable Entity",
        internal_server_error: "Internal Server Error"
      }.freeze

      included do
        rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
        rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
        rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
        rescue_from Pundit::NotAuthorizedError, with: :render_pundit_forbidden
      end

      private

      def render_error!(status, detail, errors: nil)
        body = { errors: errors || [ build_error(status, detail) ] }
        render json: body, status: status
      end

      def render_unauthorized!(detail)
        render_error!(:unauthorized, detail)
      end

      def render_validation_errors!(record)
        errors = record.errors.map do |err|
          {
            status: "422",
            title: STATUS_TITLES[:unprocessable_entity],
            detail: err.full_message,
            source: { pointer: "/data/attributes/#{err.attribute}" }
          }
        end
        render_error!(:unprocessable_entity, "validation failed", errors: errors)
      end

      def render_record_not_found(_exception)
        render_error!(:not_found, "record not found")
      end

      def render_record_invalid(exception)
        render_validation_errors!(exception.record)
      end

      def render_parameter_missing(exception)
        render_error!(:bad_request, exception.message)
      end

      def render_pundit_forbidden(_exception)
        render_error!(:forbidden, "you are not authorised to perform this action")
      end

      def build_error(status, detail)
        status_code = Rack::Utils.status_code(status).to_s
        {
          status: status_code,
          title: STATUS_TITLES[status] || status.to_s.humanize,
          detail: detail
        }
      end
    end
  end
end
