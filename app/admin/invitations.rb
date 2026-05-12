# frozen_string_literal: true

ActiveAdmin.register Invitation do
  menu priority: 6

  permit_params :email, :org_role, :organisation_id, :invited_by_id, :expires_at, :accepted_at

  filter :organisation
  filter :email
  filter :org_role, as: :select, collection: Invitation.org_roles.keys
  filter :accepted_at
  filter :expires_at
  filter :created_at

  index do
    selectable_column
    id_column
    column :email
    column(:role) { |i| i.org_role }
    column :organisation
    column :invited_by
    column :accepted_at
    column :expires_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :org_role
      row :organisation
      row :invited_by
      row :token
      row :accepted_at
      row :expires_at
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :organisation
      f.input :email
      f.input :org_role, as: :select, collection: Invitation.org_roles.keys, include_blank: false
      f.input :invited_by
      f.input :expires_at, as: :datetime_picker
      f.input :accepted_at, as: :datetime_picker
    end
    f.actions
  end
end
