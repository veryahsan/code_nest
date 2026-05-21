# frozen_string_literal: true

class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team

  scope :leads, -> { where(lead: true) }

  validates :user_id, uniqueness: { scope: :team_id }
  validate :user_matches_team_organisation
  validate :at_most_one_lead_per_team, if: :lead?

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id lead team_id updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[team user]
  end

  private

  def user_matches_team_organisation
    return if user.blank? || team.blank?

    if user.organisation_id != team.organisation_id
      errors.add(:team, "must belong to the same organisation as the user")
    end
  end

  def at_most_one_lead_per_team
    return if team.blank?

    existing = team.team_memberships.leads.where.not(id: id)
    errors.add(:lead, "only one team lead is allowed per team") if existing.exists?
  end
end
