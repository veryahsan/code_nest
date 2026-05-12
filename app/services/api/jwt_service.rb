# frozen_string_literal: true

# Thin wrapper around the `jwt` gem. Encodes and decodes HS256 tokens
# signed with Rails.application.secret_key_base. Tokens are deliberately
# short-lived (24 hours) to minimise blast radius if leaked; clients are
# expected to refresh via POST /api/v1/auth/login.
module Api
  class JwtService
    ALGORITHM = "HS256"
    DEFAULT_TTL = 24 * 60 * 60 # 24h, in seconds

    DecodeError = Class.new(StandardError)

    class << self
      def encode(payload = {}, ttl: DEFAULT_TTL, **extra)
        now = Time.current.to_i
        body = payload.to_h.merge(extra).merge(iat: now, exp: now + ttl)
        JWT.encode(body, secret, ALGORITHM)
      end

      def decode(token)
        decoded, = JWT.decode(token.to_s, secret, true, algorithm: ALGORITHM)
        decoded.with_indifferent_access
      rescue JWT::ExpiredSignature => e
        raise DecodeError, "token expired (#{e.message})"
      rescue JWT::DecodeError, JWT::VerificationError => e
        raise DecodeError, "invalid token (#{e.message})"
      end

      private

      def secret
        Rails.application.secret_key_base
      end
    end
  end
end
