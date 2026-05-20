# frozen_string_literal: true

class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.references :project, null: false, foreign_key: true

      t.integer :number, null: false
      t.string :issue_key, null: false
      t.string :summary, null: false
      t.text :description
      t.integer :issue_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1

      t.timestamps
    end

    add_index :issues, %i[project_id number], unique: true
    add_index :issues, :issue_key, unique: true
  end
end
