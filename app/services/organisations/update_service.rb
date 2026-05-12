# frozen_string_literal: true

# Updates an Organisation's mutable attributes. When the name changes
# the slug is *not* automatically regenerated — explicit slug edits go
# through this same service so admins can rename without breaking links.
module Organisations
  class UpdateService < ApplicationService
    def initialize(organisation:, attributes:)
      @organisation = organisation
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      if @organisation.update(@attributes)
        success(@organisation)
      else
        failure(@organisation)
      end
    end
  end
end
