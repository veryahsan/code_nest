# frozen_string_literal: true

# Join between a User and a Project. Projects are the unit of membership
# (they replaced Teams), so this also carries the `lead` flag that drives
# issue authorisation, and it keeps the project's group conversation in
# sync with its roster.
class ProjectMembership < ApplicationRecord
  # Project group conversations (and therefore project rosters) are capped.
  GROUP_CAPACITY = 50

  belongs_to :user
  belongs_to :project

  scope :leads, -> { where(lead: true) }

  validates :user_id, uniqueness: { scope: :project_id }
  validate :user_matches_project_organisation
  validate :at_most_one_lead_per_project, if: :lead?
  validate :within_capacity, on: :create

  after_create_commit :join_project_group
  after_create_commit :publish_membership_event
  after_destroy_commit :leave_project_group

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id lead project_id updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project user]
  end

  private

  def user_matches_project_organisation
    return if user.blank? || project.blank?

    if user.organisation_id != project.organisation_id
      errors.add(:project, "must belong to the same organisation as the user")
    end
  end

  def at_most_one_lead_per_project
    return if project.blank?

    existing = project.project_memberships.leads.where.not(id: id)
    errors.add(:lead, "only one lead is allowed per project") if existing.exists?
  end

  def within_capacity
    return if project.blank?

    if project.project_memberships.where.not(id: id).count >= GROUP_CAPACITY
      errors.add(:base, "a project is limited to #{GROUP_CAPACITY} members")
    end
  end

  def join_project_group
    project.group_conversation&.add_participant(user)
  end

  def leave_project_group
    project.group_conversation&.remove_participant(user)
  end

  # Fan out to the email + notification channels (the added user is told they
  # were added to the project). Published after commit so subscribers never see
  # uncommitted data, and from the model so every creation path is covered.
  def publish_membership_event
    Events::PublishService.call(event: "project_membership.created", project_membership: self)
  end
end
