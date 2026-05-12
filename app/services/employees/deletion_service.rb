# frozen_string_literal: true

# Destroys an Employee row. Direct reports are nullified at the model
# level (dependent: :nullify on the manager association), so the org's
# manager hierarchy survives a single deletion.
module Employees
  class DeletionService < ApplicationService
    def initialize(employee:)
      @employee = employee
    end

    def call
      if @employee.destroy
        success(@employee)
      else
        failure(@employee.errors.full_messages.to_sentence.presence || "could not delete employee")
      end
    end
  end
end
