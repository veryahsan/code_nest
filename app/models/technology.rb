# frozen_string_literal: true

class Technology < ApplicationRecord
  include Sluggable

  has_many :project_technologies, dependent: :restrict_with_error
  has_many :projects, through: :project_technologies

  validates :name, presence: true
  validates :slug, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id name slug updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project_technologies projects]
  end
end
