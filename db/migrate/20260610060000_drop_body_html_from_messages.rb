# frozen_string_literal: true

# Rich message content now lives in Action Text (`action_text_rich_texts`) via
# Message#body_text, so the legacy sanitized-HTML column is no longer read.
class DropBodyHtmlFromMessages < ActiveRecord::Migration[8.0]
  def change
    remove_column :messages, :body_html, :text
  end
end
