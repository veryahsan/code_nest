# frozen_string_literal: true

class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :organisation, null: false, foreign_key: true
      t.references :project, null: true, foreign_key: true, index: false
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.integer :kind, null: false, default: 1
      t.string :title

      t.timestamps
    end

    # A project owns at most one (auto-created) group conversation.
    add_index :conversations, :project_id, unique: true, where: "project_id IS NOT NULL",
              name: "index_conversations_on_project_id_unique"
  end
end
