# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Sign-up only: used by Users::RegistrationsController to create the tenant org.
  attr_accessor :organisation_name

  belongs_to :organisation, optional: true, inverse_of: :users

  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_one :employee, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id,
                             inverse_of: :invited_by, dependent: :nullify

  enum :org_role, { member: 0, admin: 1 }, prefix: :org

  validates :organisation, presence: true, unless: :super_admin?
  validates :organisation_id, absence: true, if: :super_admin?

  def organisation_admin?
    org_admin?
  end
end
