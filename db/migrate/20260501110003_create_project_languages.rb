# frozen_string_literal: true

class CreateProjectLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :project_languages do |t|
      t.references :project, null: false, foreign_key: true
      t.references :language, null: false, foreign_key: true

      t.timestamps
    end

    add_index :project_languages, %i[project_id language_id], unique: true,
                                                              name: "index_project_languages_unique"
  end
end
