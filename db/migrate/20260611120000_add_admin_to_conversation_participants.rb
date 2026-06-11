# frozen_string_literal: true

# Adds a group-admin flag to conversation participants. Group admins can
# remove members and delete the group. The creator of a standalone group is
# seeded as admin (see Conversations::CreateGroupService); this migration
# backfills that flag for groups that existed before the column.
class AddAdminToConversationParticipants < ActiveRecord::Migration[8.0]
  def up
    add_column :conversation_participants, :admin, :boolean, null: false, default: false

    # Backfill: the creator of a standalone group (project_id IS NULL,
    # created_by_id present) becomes its admin. Project channels have no
    # created_by_id and are managed via the project lifecycle, so they are
    # intentionally skipped.
    execute(<<~SQL.squish)
      UPDATE conversation_participants AS cp
      SET admin = true
      FROM conversations AS c
      WHERE cp.conversation_id = c.id
        AND c.project_id IS NULL
        AND c.created_by_id IS NOT NULL
        AND cp.user_id = c.created_by_id
    SQL
  end

  def down
    remove_column :conversation_participants, :admin
  end
end
