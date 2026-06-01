# frozen_string_literal: true

class Project < ApplicationRecord
  include Sluggable

  belongs_to :organisation

  has_many :project_memberships, dependent: :destroy
  has_many :users, through: :project_memberships
  has_many :project_languages, dependent: :destroy
  has_many :languages, through: :project_languages
  has_many :project_technologies, dependent: :destroy
  has_many :technologies, through: :project_technologies
  has_many :remote_resources, dependent: :destroy
  has_many :project_documents, dependent: :destroy
  has_many :issues, dependent: :destroy

  # Every project owns exactly one group conversation, created the moment
  # the project is.
  has_one :group_conversation, class_name: "Conversation", dependent: :destroy

  validates :name, presence: true
  validates :slug, uniqueness: { scope: :organisation_id }

  after_create_commit :ensure_group_conversation

  # The membership flagged as lead, if any.
  def lead_membership
    project_memberships.leads.first
  end

  def lead
    lead_membership&.user
  end

  def ensure_group_conversation
    Conversation.find_or_create_by!(project_id: id) do |conversation|
      conversation.organisation_id = organisation_id
      conversation.kind = :group
      conversation.title = name
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at description id name organisation_id slug updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[issues languages organisation project_documents project_languages
       project_technologies project_memberships remote_resources technologies users]
  end
end
