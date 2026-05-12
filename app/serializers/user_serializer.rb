# frozen_string_literal: true

class UserSerializer < ApplicationSerializer
  set_type :user

  attributes :email, :org_role, :super_admin, :confirmed_at, :created_at, :updated_at

  attribute :organisation_id do |user|
    user.organisation_id
  end
end
