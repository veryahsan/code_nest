# frozen_string_literal: true

ActiveAdmin.register Project do
  menu priority: 4

  permit_params :name, :slug, :description, :organisation_id, :team_id

  filter :organisation
  filter :team
  filter :name
  filter :slug
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :organisation
    column :team
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :description
      row :organisation
      row :team
      row :created_at
      row :updated_at
    end

    panel "Languages" do
      table_for project.languages do
        column :name
        column :code
      end
    end

    panel "Technologies" do
      table_for project.technologies do
        column :name
        column :slug
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :organisation
      f.input :team
      f.input :name
      f.input :slug
      f.input :description
    end
    f.actions
  end
end
