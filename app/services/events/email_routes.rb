# frozen_string_literal: true

# Declarative email routing for the fan-out bus.
#
# Maps each event to a lambda that, given the event payload, returns the mailer
# invocation to enqueue onto the centralized outbox — or nil to skip (guards
# like "don't email super admins" or "no inviter to notify" live here). This is
# the email-channel half of the event subscription config; Mailers::DeliveryJob
# is the generic executor that reads it. Add an event by adding a row.
#
# Spec shape: { mailer:, action:, args:, priority: }
module Events
  module EmailRoutes
    ROUTES = {
      "user.signed_up" => lambda do |user:|
        next nil if user.super_admin?

        { mailer: WelcomeMailer, action: :welcome, args: [ user ], priority: :low }
      end,

      "devise.notification" => lambda do |user:, notification:, args:|
        { mailer: Devise.mailer, action: notification.to_sym, args: [ user, *args ], priority: :high }
      end,

      "invitation.created" => lambda do |invitation:|
        { mailer: InvitationMailer, action: :invite, args: [ invitation ], priority: :default }
      end,

      "invitation.accepted" => lambda do |invitation:|
        next nil if invitation.invited_by.nil?

        { mailer: InvitationMailer, action: :accepted, args: [ invitation ], priority: :low }
      end,

      "project_membership.created" => lambda do |project_membership:|
        { mailer: ProjectMembershipMailer, action: :added, args: [ project_membership ], priority: :default }
      end
    }.freeze

    def self.spec_for(event, **payload)
      ROUTES[event]&.call(**payload)
    end
  end
end
