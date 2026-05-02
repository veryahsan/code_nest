# frozen_string_literal: true

class Team < ApplicationRecord
  include Sluggable

  belongs_to :organisation

  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships
  has_many :projects, dependent: :nullify

  validates :name, presence: true
  validates :slug, uniqueness: { scope: :organisation_id }
end
