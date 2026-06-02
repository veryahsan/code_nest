# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :notifiable, null: false, polymorphic: true
      t.string :kind, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, %i[recipient_id notifiable_type notifiable_id kind],
              unique: true,
              name: "index_notifications_uniqueness"

    add_index :notifications, %i[recipient_id read_at],
              name: "index_notifications_on_recipient_and_read_at"
  end
end
