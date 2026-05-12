# frozen_string_literal: true

ActiveAdmin.register Language do
  menu priority: 10

  permit_params :name, :code

  filter :name
  filter :code
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :code
    column(:projects_count) { |l| l.projects.count }
    column :created_at
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :code, hint: "Lowercase identifier — e.g. ruby, typescript, python."
    end
    f.actions
  end
end
