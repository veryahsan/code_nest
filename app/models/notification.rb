# frozen_string_literal: true

# A single in-app notification delivered to one recipient.
#
# Created by Notifications::FanoutJob when a domain event occurs (e.g. a new
# message in a conversation the recipient participates in). The same job also
# broadcasts the payload to NotificationsChannel so connected clients receive
# the badge update in real time.
#
# Uniqueness (recipient + notifiable + kind) prevents duplicate rows when a job
# retries — use find_or_create_by! on those three columns when inserting.
class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor,     class_name: "User"
  belongs_to :notifiable, polymorphic: true

  validates :kind, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read,   -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_read!
    touch(:read_at) unless read?
  end
end
