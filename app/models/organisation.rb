# frozen_string_literal: true

# A tenant root. Pure data + integrity rules — all creation, slug
# generation, and domain-matching logic lives in app/services and
# app/facades (see Organisations::CreationFacade,
# Organisations::GenerateUniqueSlugService,
# Organisations::FindByEmailDomainService).
class Organisation < ApplicationRecord
  include Sluggable

  has_many :users, inverse_of: :organisation, dependent: :restrict_with_error
  has_many :teams, dependent: :restrict_with_error
  has_many :employees, dependent: :restrict_with_error
  has_many :invitations, dependent: :destroy
  has_many :projects, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id name slug updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[employees invitations projects teams users]
  end
end
