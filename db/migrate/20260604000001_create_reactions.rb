# frozen_string_literal: true

class CreateReactions < ActiveRecord::Migration[8.0]
  def change
    create_table :reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reactable, null: false, polymorphic: true
      t.integer :kind, null: false, default: 0

      t.timestamps
    end

    add_index :reactions, %i[user_id reactable_type reactable_id kind],
              unique: true, name: "index_reactions_uniqueness"
  end
end
