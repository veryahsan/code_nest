# frozen_string_literal: true

# Project-wide base for every JSON:API serializer that powers /api/v1.
# Adds a few sensible defaults (timestamps, key transform) on top of the
# `jsonapi-serializer` gem. Subclasses just declare attributes/relationships.
class ApplicationSerializer
  include JSONAPI::Serializer

  set_key_transform :underscore
end
