# frozen_string_literal: true

class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team

  validates :user_id, uniqueness: { scope: :team_id }

  validate :user_matches_team_organisation

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id team_id updated_at user_id]
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
end
