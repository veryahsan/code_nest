# frozen_string_literal: true

ActiveAdmin.register TeamMembership do
  menu priority: 7

  permit_params :user_id, :team_id

  filter :team
  filter :user
  filter :created_at

  index do
    selectable_column
    id_column
    column :team
    column :user
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :team
      row :user
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :team
      f.input :user
    end
    f.actions
  end
end
