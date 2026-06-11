# frozen_string_literal: true

# A comment left by a user on any commentable record (issues and projects
# today; more later). Polymorphic on `commentable`. Comments are reactable
# just like messages (via the Reactable concern).
class Comment < ApplicationRecord
  include Reactable

  belongs_to :user
  belongs_to :commentable, polymorphic: true

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :chronological, -> { order(:created_at) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[body commentable_id commentable_type created_at id updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[commentable reactions user]
  end
end
