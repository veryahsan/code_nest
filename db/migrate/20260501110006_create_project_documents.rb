# frozen_string_literal: true

class CreateProjectDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :project_documents do |t|
      t.references :project, null: false, foreign_key: true

      t.string :title, null: false
      t.string :external_id
      t.string :url
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :project_documents, :external_id
  end
end
