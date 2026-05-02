# frozen_string_literal: true

class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :organisation, null: false, foreign_key: true
      t.references :invited_by, null: true, foreign_key: { to_table: :users }

      t.string :email, null: false
      t.string :token, null: false
      t.integer :org_role, null: false, default: 0
      t.datetime :expires_at
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, %i[organisation_id email],
              unique: true,
              where: "accepted_at IS NULL",
              name: "index_invitations_pending_email_per_organisation"
  end
end
