# frozen_string_literal: true

ActiveAdmin.register ProjectDocument do
  menu priority: 8

  permit_params :project_id, :title, :url, :external_id, :metadata

  filter :project
  filter :title
  filter :external_id
  filter :created_at

  index do
    selectable_column
    id_column
    column :title
    column :project
    column :url
    column :external_id
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :title
      row :project
      row :url
      row :external_id
      row(:metadata) { |d| d.metadata.present? ? JSON.pretty_generate(d.metadata) : "—" }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :project
      f.input :title
      f.input :url
      f.input :external_id
      f.input :metadata, as: :text, hint: "JSON object stored in the metadata column."
    end
    f.actions
  end
end
