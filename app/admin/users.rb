# frozen_string_literal: true

ActiveAdmin.register User do
  menu priority: 2

  permit_params :email, :org_role, :super_admin, :organisation_id, :password, :password_confirmation

  filter :email
  filter :super_admin
  filter :org_role, as: :select, collection: User.org_roles.keys
  filter :organisation
  filter :confirmed_at
  filter :created_at

  index do
    selectable_column
    id_column
    column :email
    column(:role) { |u| u.org_role }
    column :super_admin
    column :organisation
    column :confirmed_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :super_admin
      row :org_role
      row :organisation
      row :confirmed_at
      row :sign_in_count
      row :created_at
      row :updated_at
    end

    panel "Identities" do
      table_for user.identities do
        column :provider
        column :uid
        column :email
        column :created_at
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :email
      f.input :super_admin, hint: "Platform-wide administrator. Cannot belong to an organisation."
      f.input :org_role, as: :select, collection: User.org_roles.keys, include_blank: false
      f.input :organisation, hint: "Leave blank to detach the user from any organisation."
      f.input :password, hint: "Leave blank to keep the existing password."
      f.input :password_confirmation
    end
    f.actions
  end

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      super
    end
  end
end
