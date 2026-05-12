# frozen_string_literal: true

ActiveAdmin.register Team do
  menu priority: 3

  permit_params :name, :slug, :organisation_id

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
    column(:members) { |t| t.users.count }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :organisation
      row :created_at
      row :updated_at
    end

    panel "Members" do
      table_for team.users.order(:email).limit(100) do
        column :email
        column(:role) { |u| u.org_role }
      end
    end

    panel "Projects" do
      table_for team.projects.order(:name) do
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
    end
    f.actions
  end
end
