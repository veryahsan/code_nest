# frozen_string_literal: true

# Stores the link between a User and an external identity provider
# (Google, GitHub, ...). One user can have many identities, so adding a
# second provider later is a no-schema-change operation.
#
# `raw_info` keeps the provider's most recent `extra.raw_info` payload so
# we can debug attribution issues without re-hitting the provider API.
class CreateIdentities < ActiveRecord::Migration[8.0]
  def change
    create_table :identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.jsonb :raw_info, default: {}, null: false

      t.timestamps
    end

    add_index :identities, [ :provider, :uid ], unique: true
  end
end
