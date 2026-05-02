# frozen_string_literal: true

# Base class for JSON:API serializers used by the /api/v1 surface.
class ApplicationSerializer
  include JSONAPI::Serializer
end
