# frozen_string_literal: true

# Wraps Organisations::UpdateService so the controller stays thin and
# future cross-cutting work (audit log, broadcasts) can attach here.
module Organisations
  class UpdateFacade < ApplicationFacade
    def initialize(organisation:, attributes:)
      @organisation = organisation
      @attributes = attributes
    end

    def call
      Organisations::UpdateService.call(organisation: @organisation, attributes: @attributes)
    end
  end
end
