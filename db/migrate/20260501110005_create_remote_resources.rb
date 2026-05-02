# frozen_string_literal: true

class CreateRemoteResources < ActiveRecord::Migration[8.0]
  def change
    create_table :remote_resources do |t|
      t.references :project, null: false, foreign_key: true

      t.string :name, null: false
      t.string :kind, null: false
      t.text :credentials_ciphertext
      t.string :url

      t.timestamps
    end
  end
end
