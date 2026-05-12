# frozen_string_literal: true

# Active Admin panel for RemoteResource. Deliberately omits any
# decrypted credentials display — secrets are managed only through the
# tenant-facing Hotwire admin UI where Lockbox + the policy-gated
# `view_credentials?` check work together.
ActiveAdmin.register RemoteResource do
  menu priority: 9

  permit_params :project_id, :name, :kind, :url

  filter :project
  filter :name
  filter :kind
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :project
    column :kind
    column :url
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :project
      row :kind
      row :url
      row :created_at
      row :updated_at
      row(:credentials) { "(hidden)" }
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :project
      f.input :name
      f.input :kind
      f.input :url
    end
    f.actions
  end
end
