# frozen_string_literal: true

module ApiHelpers
  def auth_headers_for(user)
    token = Api::JwtService.encode(sub: user.id, email: user.email)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
