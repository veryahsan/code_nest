# frozen_string_literal: true

# Some notifications are system-generated and have no acting user (e.g. "you
# were added to a project", where the model callback that publishes the event
# does not know which admin performed the add). Allow actor_id to be null so the
# fan-out bus can record actorless notifications.
class AllowNullActorOnNotifications < ActiveRecord::Migration[8.0]
  def change
    change_column_null :notifications, :actor_id, true
  end
end
