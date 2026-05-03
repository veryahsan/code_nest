# frozen_string_literal: true

# Adds Devise's :confirmable columns to users so we can enforce email
# verification at sign-up. Existing rows are backfilled with confirmed_at = NOW()
# so seeded/dev/staging accounts are not retroactively locked out.
class AddConfirmableToUsers < ActiveRecord::Migration[8.0]
  def up
    change_table :users, bulk: true do |t|
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # supports Devise reconfirmable on email change
    end

    add_index :users, :confirmation_token, unique: true

    # Mark every existing user as already confirmed; we only want the gate to
    # apply to accounts created from this point forward.
    execute "UPDATE users SET confirmed_at = NOW() WHERE confirmed_at IS NULL"
  end

  def down
    remove_index :users, :confirmation_token
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
  end
end
