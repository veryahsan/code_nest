# frozen_string_literal: true

# Upsert service for RemoteResource. Accepts a JSON string of
# credentials and stores them through the model's `has_encrypted
# :credentials` Lockbox-backed attribute. Empty credential strings are
# left untouched so an admin can edit non-secret fields without rotating
# the key.
module RemoteResources
  class UpsertService < ApplicationService
    def initialize(remote_resource:, attributes:)
      @resource = remote_resource
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      @resource.assign_attributes(
        name: @attributes[:name],
        kind: @attributes[:kind],
        url: @attributes[:url],
      )

      if @attributes.key?(:credentials_json)
        creds_result = parse_credentials(@attributes[:credentials_json])
        if creds_result.failure?
          @resource.errors.add(:credentials, creds_result.error)
          return failure(@resource)
        end
        @resource.credentials = creds_result.value if creds_result.value.present?
      end

      if @resource.save
        success(@resource)
      else
        failure(@resource)
      end
    end

    private

    def parse_credentials(raw)
      return success(nil) if raw.blank?
      return success(raw) if raw.is_a?(Hash)

      parsed = JSON.parse(raw)
      return failure("must be a JSON object") unless parsed.is_a?(Hash)

      success(parsed.to_json)
    rescue JSON::ParserError => e
      failure("is not valid JSON (#{e.message})")
    end
  end
end
