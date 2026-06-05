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

    MAX_HANDLE_RETRIES = 3

    def call
      @employee = @organisation.employees.new(
        user_id: @attributes[:user_id],
        manager_id: @attributes[:manager_id].presence,
        display_name: @attributes[:display_name],
        job_title: @attributes[:job_title],
      )

      save_with_handle_retry
    end

    private

    # The handle's uniqueness is guarded by a DB index, so a rare concurrent
    # insert can raise RecordNotUnique even though validation passed. Clear the
    # handle and retry so a fresh candidate is generated.
    def save_with_handle_retry
      attempts = 0

      begin
        @employee.save ? success(@employee) : failure(@employee)
      rescue ActiveRecord::RecordNotUnique
        raise if (attempts += 1) > MAX_HANDLE_RETRIES

        @employee.handle = nil
        retry
      end
    end
  end
end
