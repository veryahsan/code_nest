# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = Rails.env.production?
  config.lograge.formatter = Lograge::Formatters::KeyValue.new
  config.lograge.custom_options = lambda do |event|
    {
      time: event.time.iso8601,
      params: event.payload[:params].except("controller", "action", "format", "id"),
      request_id: event.payload[:request_id],
      remote_ip: event.payload[:remote_ip],
      user_id: event.payload[:user_id]
    }.compact
  end
end
