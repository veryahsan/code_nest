# frozen_string_literal: true

# Updates an Employee's HR fields and manager. The user_id is
# intentionally not editable — once an Employee row is associated with
# a User, swapping the underlying User would break audit trails.
module Employees
  class UpdateFacade < ApplicationFacade
    EDITABLE_ATTRIBUTES = %i[display_name job_title manager_id].freeze

    def initialize(employee:, attributes:)
      @employee = employee
      @attributes = attributes.to_h.symbolize_keys.slice(*EDITABLE_ATTRIBUTES)
      @attributes[:manager_id] = @attributes[:manager_id].presence if @attributes.key?(:manager_id)
    end

    def call
      if @employee.update(@attributes)
        success(@employee)
      else
        failure(@employee)
      end
    end
  end
end
