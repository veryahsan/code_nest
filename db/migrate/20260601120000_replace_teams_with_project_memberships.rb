# frozen_string_literal: true

# Projects become the unit of membership: `team`/`team_membership` are
# retired and `project_memberships` (carrying the lead flag) take over.
# Existing team memberships are projected onto every project owned by the
# team so no membership data is silently lost.
class ReplaceTeamsWithProjectMemberships < ActiveRecord::Migration[8.0]
  def up
    create_table :project_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.boolean :lead, null: false, default: false

      t.timestamps
    end

    add_index :project_memberships, %i[user_id project_id], unique: true
    add_index :project_memberships, %i[project_id lead],
              where: "lead = true",
              unique: true,
              name: "index_project_memberships_on_project_id_unique_lead"

    # Backfill: every team membership becomes a membership of each project
    # owned by that team, preserving the lead flag.
    execute(<<~SQL.squish)
      INSERT INTO project_memberships (user_id, project_id, lead, created_at, updated_at)
      SELECT tm.user_id, p.id, tm.lead, NOW(), NOW()
      FROM team_memberships tm
      JOIN projects p ON p.team_id = tm.team_id
      ON CONFLICT (user_id, project_id) DO NOTHING;
    SQL

    remove_reference :projects, :team, foreign_key: true, index: true

    drop_table :team_memberships
    drop_table :teams
  end

  def down
    create_table :teams do |t|
      t.references :organisation, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end
    add_index :teams, %i[organisation_id slug], unique: true

    create_table :team_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.boolean :lead, null: false, default: false

      t.timestamps
    end
    add_index :team_memberships, %i[user_id team_id], unique: true
    add_index :team_memberships, %i[team_id lead],
              where: "lead = true",
              unique: true,
              name: "index_team_memberships_on_team_id_unique_lead"

    add_reference :projects, :team, null: true, foreign_key: true, index: true

    drop_table :project_memberships
  end
end
