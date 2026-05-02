# frozen_string_literal: true

class CreateTechnologies < ActiveRecord::Migration[8.0]
  def change
    create_table :technologies do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :technologies, :slug, unique: true
  end
end
