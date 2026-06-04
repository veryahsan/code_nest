# frozen_string_literal: true

# A reaction left by a user on any reactable record (messages today;
# comments/posts later). Polymorphic on `reactable`. A user may leave at most
# one reaction of each kind per record (enforced by a unique DB index).
class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :reactable, polymorphic: true

  enum :kind, { like: 0, love: 1, laugh: 2, celebrate: 3, insightful: 4, sad: 5 }

  # Single source of truth for the emoji shown per kind, shared by the picker UI
  # and any future server-rendered reaction summaries.
  KIND_EMOJI = {
    "like"       => "\u{1F44D}",
    "love"       => "\u{2764}\u{FE0F}",
    "laugh"      => "\u{1F602}",
    "celebrate"  => "\u{1F389}",
    "insightful" => "\u{1F4A1}",
    "sad"        => "\u{1F622}",
  }.freeze

  validates :kind, presence: true
  validates :user_id, uniqueness: { scope: %i[reactable_type reactable_id kind] }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id kind reactable_id reactable_type updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[reactable user]
  end
end
