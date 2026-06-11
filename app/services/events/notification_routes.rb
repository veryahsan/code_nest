# frozen_string_literal: true

# Declarative in-app notification routing for the fan-out bus.
#
# Maps each event to a lambda that, given the event payload, returns a list of
# "deliveries". Each delivery names its recipients (by id, so fan-out to a large
# audience stays cheap), the actor (or nil for system notifications), the
# polymorphic notifiable, and the notification kind. A single event can produce
# several deliveries — e.g. a new message notifies all participants
# ("message_created") and, additively, anyone mentioned ("user_mentioned").
#
# This is the notification-channel half of the event subscription config;
# Notifications::DeliveryJob is the generic dispatcher that reads it and
# enqueues one Notifications::RecordJob per recipient.
#
# Delivery shape: { recipient_ids:, actor_id:, notifiable:, kind: }
module Events
  module NotificationRoutes
    ROUTES = {
      "message.created" => lambda do |message:|
        [
          {
            recipient_ids: message.conversation.participants.where.not(id: message.user_id).pluck(:id),
            actor_id:      message.user_id,
            notifiable:    message,
            kind:          "message_created"
          },
          {
            recipient_ids: message.message_mentions.pluck(:mentioned_user_id),
            actor_id:      message.user_id,
            notifiable:    message,
            kind:          "user_mentioned"
          }
        ]
      end,

      "invitation.accepted" => lambda do |invitation:|
        inviter = invitation.invited_by
        next [] if inviter.nil?

        [ {
          recipient_ids: [ inviter.id ],
          actor_id:      User.find_by(email: invitation.email)&.id,
          notifiable:    invitation,
          kind:          "invitation_accepted"
        } ]
      end,

      "project_membership.created" => lambda do |project_membership:|
        [ {
          recipient_ids: [ project_membership.user_id ],
          actor_id:      nil,
          notifiable:    project_membership.project,
          kind:          "project_membership_created"
        } ]
      end
    }.freeze

    def self.deliveries_for(event, **payload)
      Array(ROUTES[event]&.call(**payload))
    end
  end
end
