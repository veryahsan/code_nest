# frozen_string_literal: true

ActiveAdmin.register Employee do
  menu priority: 5

  permit_params :user_id, :organisation_id, :manager_id, :display_name, :job_title

  filter :organisation
  filter :user
  filter :display_name
  filter :job_title
  filter :created_at

  index do
    selectable_column
    id_column
    column :display_name
    column :job_title
    column :organisation
    column :user
    column :manager
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :display_name
      row :job_title
      row :organisation
      row :user
      row :manager
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :organisation
      f.input :user
      f.input :manager
      f.input :display_name
      f.input :job_title
    end
    f.actions
  end
end
