# frozen_string_literal: true

# Identities are minted exclusively by the OmniAuth callback flow
# (Users::CreateFromOmniauthService / Users::LinkOmniauthIdentityService).
# Editing them by hand is dangerous — if you change the (provider, uid)
# pair you risk hijacking another user's SSO record. So this panel is
# intentionally read-only.
ActiveAdmin.register Identity do
  menu priority: 12

  actions :index, :show

  filter :provider, as: :select, collection: Identity::PROVIDERS
  filter :uid
  filter :user
  filter :created_at

  index do
    selectable_column
    id_column
    column :provider
    column :uid
    column :email
    column :user
    column :created_at
  end

  show do
    attributes_table do
      row :id
      row :provider
      row :uid
      row :email
      row :user
      row :raw_info
      row :created_at
      row :updated_at
    end
  end
end
