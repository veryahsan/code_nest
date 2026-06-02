# frozen_string_literal: true

# In-app notifications for the signed-in user. Real-time delivery is handled
# by NotificationsChannel; these actions cover the full-page list and the
# mark-as-read interactions behind the sidebar dropdown.
class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_notification, only: :read

  def index
    @pagy, @notifications = pagy(
      current_user.notifications
                  .recent
                  .includes(:actor, :notifiable),
    )
  end

  def read
    @notification.mark_read!
    redirect_to notification_target_path(@notification)
  end

  def read_all
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back(fallback_location: notifications_path)
  end

  private

  def load_notification
    @notification = current_user.notifications.find(params[:id])
  end

  # Resolve where a notification should take the user. Today every notifiable
  # is a Message, so we land on its conversation; unknown types fall back to
  # the notifications list.
  def notification_target_path(notification)
    notifiable = notification.notifiable
    return conversation_path(notifiable.conversation_id) if notifiable.is_a?(Message)

    notifications_path
  end
end
