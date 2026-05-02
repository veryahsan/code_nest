# frozen_string_literal: true

class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :organisation, null: false, foreign_key: true
      t.references :manager, null: true, foreign_key: { to_table: :employees }

      t.string :display_name
      t.string :job_title

      t.timestamps
    end
  end
end
