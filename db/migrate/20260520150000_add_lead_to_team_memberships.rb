# frozen_string_literal: true

class AddLeadToTeamMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :team_memberships, :lead, :boolean, null: false, default: false
    add_index :team_memberships, %i[team_id lead],
              where: "lead = true",
              unique: true,
              name: "index_team_memberships_on_team_id_unique_lead"
  end
end
