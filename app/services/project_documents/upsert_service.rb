# frozen_string_literal: true

# Single service that handles both create and update for ProjectDocument.
# Accepts a metadata JSON string and parses/normalises it into the JSONB
# column, surfacing parse errors as form-friendly errors.
module ProjectDocuments
  class UpsertService < ApplicationService
    def initialize(document:, attributes:)
      @document = document
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      @document.assign_attributes(
        title: @attributes[:title],
        url: @attributes[:url],
        external_id: @attributes[:external_id],
      )

      metadata_result = parse_metadata
      if metadata_result.failure?
        @document.errors.add(:metadata, metadata_result.error)
        return failure(@document)
      end
      @document.metadata = metadata_result.value

      if @document.save
        success(@document)
      else
        failure(@document)
      end
    end

    private

    def parse_metadata
      raw = @attributes[:metadata]
      return success({}) if raw.blank?
      return success(raw) if raw.is_a?(Hash)

      parsed = JSON.parse(raw)
      return failure("must be a JSON object") unless parsed.is_a?(Hash)

      success(parsed)
    rescue JSON::ParserError => e
      failure("is not valid JSON (#{e.message})")
    end
  end
end
