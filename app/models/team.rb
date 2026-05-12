# frozen_string_literal: true

class Team < ApplicationRecord
  include Sluggable

  belongs_to :organisation

  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships
  has_many :projects, dependent: :nullify

  validates :name, presence: true
  validates :slug, uniqueness: { scope: :organisation_id }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id name organisation_id slug updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[organisation projects team_memberships users]
  end
end
