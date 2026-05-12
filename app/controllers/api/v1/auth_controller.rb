# frozen_string_literal: true

# Issues short-lived JWTs for API consumers. Validates email + password
# via Devise's `valid_password?`; super admins and unconfirmed users are
# explicitly rejected so the API mirrors the Hotwire login rules.
module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_api_user!, only: %i[login]

      def login
        email = params.dig(:auth, :email).to_s.downcase.strip
        password = params.dig(:auth, :password).to_s

        return render_error!(:bad_request, "email and password are required") if email.blank? || password.blank?

        user = User.find_by(email: email)
        unless user&.valid_password?(password)
          return render_unauthorized!("invalid email or password")
        end

        unless user.confirmed?
          return render_unauthorized!("email address is not confirmed yet")
        end

        token = Api::JwtService.encode(sub: user.id, email: user.email)
        render json: {
          data: {
            token: token,
            expires_in: Api::JwtService::DEFAULT_TTL,
            user: UserSerializer.new(user).serializable_hash[:data]
          }
        }, status: :ok
      end
    end
  end
end
