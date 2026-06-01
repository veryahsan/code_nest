# frozen_string_literal: true

ActiveAdmin.register ProjectMembership do
  menu priority: 7

  permit_params :user_id, :project_id, :lead

  filter :project
  filter :user
  filter :lead
  filter :created_at

  index do
    selectable_column
    id_column
    column :project
    column :user
    column :lead
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :project
      row :user
      row :lead
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :project
      f.input :user
      f.input :lead
    end
    f.actions
  end
end
