# frozen_string_literal: true

# A reaction left by a user on any reactable record (messages today;
# comments/posts later). Polymorphic on `reactable`. A user may leave at most
# one reaction of each kind per record (enforced by a unique DB index).
class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :reactable, polymorphic: true

  enum :kind, { like: 0, love: 1, laugh: 2, celebrate: 3, insightful: 4, sad: 5 }

  validates :kind, presence: true
  validates :user_id, uniqueness: { scope: %i[reactable_type reactable_id kind] }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id kind reactable_id reactable_type updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[reactable user]
  end
end
