# frozen_string_literal: true

class Issue < ApplicationRecord
  belongs_to :project, touch: true

  enum :issue_type, { task: 0, bug: 1, story: 2, epic: 3 }, prefix: true
  enum :status, { pending: 0, in_progress: 1, done: 2 }, prefix: true
  enum :priority, { low: 0, medium: 1, high: 2, critical: 3 }, prefix: true

  validates :summary, presence: true, length: { maximum: 255 }
  validates :number, presence: true,
                     numericality: { only_integer: true, greater_than: 0 },
                     uniqueness: { scope: :project_id }
  validates :issue_key, presence: true, uniqueness: true

  before_validation :normalize_summary, on: %i[create update]
  before_validation :assign_sequence_and_key, on: :create

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at description id issue_key issue_type number priority project_id status summary updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project]
  end

  private

  def normalize_summary
    self.summary = summary.to_s.strip.presence
  end

  def assign_sequence_and_key
    return if project.blank?

    project.with_lock do
      self.number = project.issues.maximum(:number).to_i + 1
      self.issue_key = "#{project.slug.upcase.tr('-', '')}-#{number}"
    end
  end
end
