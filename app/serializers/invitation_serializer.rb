# frozen_string_literal: true

class InvitationSerializer < ApplicationSerializer
  set_type :invitation

  attributes :email, :org_role, :expires_at, :accepted_at, :created_at, :updated_at

  attribute :organisation_id
  attribute :invited_by_id
  attribute :pending do |invitation|
    invitation.accepted_at.nil?
  end
end
