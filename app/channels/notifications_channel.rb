# frozen_string_literal: true

# Per-user Action Cable stream for in-app notifications.
#
# Auth is enforced at the connection level (ApplicationCable::Connection rejects
# unauthenticated sockets), so current_user is always present here. No further
# participation check is needed — users only receive their own notifications.
#
# Broadcasts are sent by Notifications::DeliverJob whenever a Notification row
# is created for this user.
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end
end
