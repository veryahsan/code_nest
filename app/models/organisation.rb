# frozen_string_literal: true

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
