# frozen_string_literal: true

class TeamMembershipSerializer < ApplicationSerializer
  set_type :team_membership

  attributes :team_id, :user_id, :created_at
end
