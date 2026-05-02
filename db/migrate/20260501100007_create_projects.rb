# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :organisation, null: false, foreign_key: true
      t.references :team, null: true, foreign_key: true

      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :projects, %i[organisation_id slug], unique: true
  end
end
