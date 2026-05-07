# frozen_string_literal: true

# Boots OmniAuth into test mode for every spec, then resets the mock
# table afterwards so individual tests can stub their own auth payload
# without leaking state.
OmniAuth.config.test_mode = true
OmniAuth.config.logger = Logger.new(File::NULL)

module OmniauthSpecHelpers
  def mock_omniauth(provider, uid:, email:, name: "Sam Sample", raw_info: {})
    OmniAuth.config.mock_auth[provider.to_sym] = OmniAuth::AuthHash.new(
      provider: provider.to_s,
      uid: uid,
      info: { email: email, name: name },
      extra: { raw_info: raw_info },
    )
  end

  def mock_omniauth_failure(provider, reason = :invalid_credentials)
    OmniAuth.config.mock_auth[provider.to_sym] = reason
  end
end

RSpec.configure do |config|
  config.include OmniauthSpecHelpers, type: :request
  config.include OmniauthSpecHelpers, type: :service

  config.after do
    OmniAuth.config.mock_auth.each_key { |k| OmniAuth.config.mock_auth[k] = nil }
  end
end
