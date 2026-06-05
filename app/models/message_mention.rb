# frozen_string_literal: true

# Join record linking a message to a user explicitly @mentioned in its body.
# Rows are written synchronously when the message is created (see
# Messages::CreateService) so the async notification pipeline can fan out from
# a persisted, queryable source rather than re-parsing the body.
class MessageMention < ApplicationRecord
  belongs_to :message
  belongs_to :mentioned_user, class_name: "User"
end
