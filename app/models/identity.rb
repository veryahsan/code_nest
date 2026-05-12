# frozen_string_literal: true

# A single (provider, uid) pair owned by a User. One User can hold many
# identities (e.g. Google + GitHub for the same person), and we look users
# up by [provider, uid] in the OmniAuth callback.
#
# All identity bookkeeping is mutated through the
# `Users::LinkOmniauthIdentityService` and `Users::CreateFromOmniauthService`
# objects, both orchestrated by `Users::OmniauthAuthenticationFacade`.
# Controllers must never write to this table directly.
class Identity < ApplicationRecord
  PROVIDERS = %w[google_oauth2 github].freeze

  belongs_to :user

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :uid, presence: true, uniqueness: { scope: :provider }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id provider uid updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end
end
