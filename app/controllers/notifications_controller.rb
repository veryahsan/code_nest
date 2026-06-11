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

  # Resolve where a notification should take the user, based on its notifiable:
  # a Message lands on its conversation, a Project on the project page, an
  # accepted Invitation on the invitations list. Unknown/deleted notifiables
  # fall back to the notifications list.
  def notification_target_path(notification)
    case notification.notifiable
    when Message    then conversation_path(notification.notifiable.conversation_id)
    when Project    then project_path(notification.notifiable)
    when Invitation then invitations_path
    else notifications_path
    end
  end
end
