# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :commentable, null: false, polymorphic: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :comments, %i[commentable_type commentable_id created_at],
              name: "index_comments_on_commentable_and_created_at"
  end
end
