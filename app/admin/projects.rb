# frozen_string_literal: true

ActiveAdmin.register Project do
  menu priority: 4

  permit_params :name, :slug, :description, :organisation_id

  filter :organisation
  filter :name
  filter :slug
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :organisation
    column(:members) { |p| p.users.count }
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
      row :created_at
      row :updated_at
    end

    panel "Members" do
      table_for project.project_memberships.includes(:user) do
        column(:email) { |m| m.user.email }
        column :lead
      end
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
      f.input :name
      f.input :slug
      f.input :description
    end
    f.actions
  end
end
