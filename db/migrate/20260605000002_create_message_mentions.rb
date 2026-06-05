# frozen_string_literal: true

class CreateMessageMentions < ActiveRecord::Migration[8.0]
  def change
    create_table :message_mentions do |t|
      t.references :message, null: false, foreign_key: true
      t.references :mentioned_user, null: false, foreign_key: { to_table: :users }

      t.datetime :created_at, null: false
    end

    add_index :message_mentions, %i[message_id mentioned_user_id], unique: true
  end
end
