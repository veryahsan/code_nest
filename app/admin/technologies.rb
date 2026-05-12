# frozen_string_literal: true

ActiveAdmin.register Technology do
  menu priority: 11

  permit_params :name, :slug

  filter :name
  filter :slug
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column(:projects_count) { |t| t.projects.count }
    column :created_at
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :slug, hint: "URL-safe identifier; auto-derived from the name when blank."
    end
    f.actions
  end
end
