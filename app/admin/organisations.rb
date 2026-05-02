# frozen_string_literal: true

ActiveAdmin.register Organisation do
  menu priority: 1, label: "Organisations"

  permit_params :name, :slug

  filter :name
  filter :slug
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column(:users_count) { |org| org.users.count }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :created_at
      row :updated_at
    end

    panel "Users in this organisation" do
      table_for organisation.users.order(:email).limit(100) do
        column :email
        column(:role) { |u| u.org_role }
        column :super_admin
        column :created_at
      end
    end

    panel "Teams" do
      table_for organisation.teams.order(:name) do
        column :name
        column :slug
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :slug, hint: "URL-safe identifier (lowercase, hyphens). Saved values are normalized automatically."
    end
    f.actions
  end
end
