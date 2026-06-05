# frozen_string_literal: true

class AddBodyHtmlToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :body_html, :text
  end
end
