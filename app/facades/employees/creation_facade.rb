# frozen_string_literal: true

# Builds and persists an Employee row inside an organisation. The
# trickier validations (user must belong to the same org, manager must
# too, no super admins) live on the model — this facade just sets up
# the associations and surfaces a uniform Result.
module Employees
  class CreationFacade < ApplicationFacade
    def initialize(organisation:, attributes:)
      @organisation = organisation
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      @employee = @organisation.employees.new(
        user_id: @attributes[:user_id],
        manager_id: @attributes[:manager_id].presence,
        display_name: @attributes[:display_name],
        job_title: @attributes[:job_title],
      )

      if @employee.save
        success(@employee)
      else
        failure(@employee)
      end
    end
  end
end
