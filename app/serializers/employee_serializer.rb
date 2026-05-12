# frozen_string_literal: true

class EmployeeSerializer < ApplicationSerializer
  set_type :employee

  attributes :display_name, :job_title, :created_at, :updated_at

  attribute :user_id
  attribute :organisation_id
  attribute :manager_id
end
