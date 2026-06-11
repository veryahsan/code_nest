# frozen_string_literal: true

class Issue < ApplicationRecord
  belongs_to :project, touch: true
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :assignor, class_name: "User", optional: true

  has_many_attached :attachments
  has_many :comments, as: :commentable, dependent: :destroy

  enum :issue_type, { task: 0, bug: 1, story: 2, epic: 3 }, prefix: true
  enum :status, { pending: 0, in_progress: 1, done: 2 }, prefix: true
  enum :priority, { low: 0, medium: 1, high: 2, critical: 3 }, prefix: true

  validates :summary, presence: true, length: { maximum: 255 }
  validates :number, presence: true,
                     numericality: { only_integer: true, greater_than: 0 },
                     uniqueness: { scope: :project_id }
  validates :issue_key, presence: true, uniqueness: true
  validate :assignee_in_project_organisation
  validate :assignor_in_project_organisation

  before_validation :normalize_summary, on: %i[create update]
  before_validation :assign_sequence_and_key, on: :create

  # Notify the assignee whenever an issue is (re)assigned to someone. Published
  # after commit so subscribers never see uncommitted data; the actor is the
  # issue's own assignor field since the model has no current_user.
  after_update_commit :publish_assignment_event

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at description id issue_key issue_type number priority project_id status summary updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[assignee assignor comments project]
  end

  private

  def normalize_summary
    self.summary = summary.to_s.strip.presence
  end

  def assignee_in_project_organisation
    return if assignee.blank? || project.blank?

    if assignee.organisation_id != project.organisation_id
      errors.add(:assignee, "must belong to the same organisation as the project")
    end
  end

  def assignor_in_project_organisation
    return if assignor.blank? || project.blank?

    if assignor.organisation_id != project.organisation_id
      errors.add(:assignor, "must belong to the same organisation as the project")
    end
  end

  def publish_assignment_event
    return unless saved_change_to_assignee_id?
    return if assignee_id.nil?

    Events::PublishService.call(event: "issue.assigned", issue: self)
  end

  def assign_sequence_and_key
    return if project.blank?

    project.with_lock do
      self.number = project.issues.maximum(:number).to_i + 1
      self.issue_key = "#{project.slug.upcase.tr('-', '')}-#{number}"
    end
  end
end
