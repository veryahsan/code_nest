# frozen_string_literal: true

class AddHandleToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :handle, :string

    add_index :employees, %i[organisation_id handle],
              unique: true,
              name: "index_employees_on_org_and_handle"
  end
end
