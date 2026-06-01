# frozen_string_literal: true

class ProjectMembershipSerializer < ApplicationSerializer
  set_type :project_membership

  attributes :project_id, :user_id, :lead, :created_at
end
