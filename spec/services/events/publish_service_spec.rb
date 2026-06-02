# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::PublishService, type: :service do
  it "enqueues the correct subscriber job for each registered event" do
    user       = create(:user)
    invitation = create(:invitation)
    message    = create(:message)
    clear_enqueued_jobs

    expect { described_class.call(event: "user.signed_up", user: user) }
      .to have_enqueued_job(Mailers::WelcomeEmailJob)

    expect { described_class.call(event: "invitation.created", invitation: invitation) }
      .to have_enqueued_job(Mailers::InvitationEmailJob)

    expect { described_class.call(event: "message.created", message: message) }
      .to have_enqueued_job(Notifications::FanoutJob)
  end

  it "enqueues Mailers::DeviseNotificationJob for devise.notification" do
    user = create(:user)
    clear_enqueued_jobs

    expect {
      described_class.call(
        event:        "devise.notification",
        user:         user,
        notification: "confirmation_instructions",
        args:         ["some_token", {}]
      )
    }.to have_enqueued_job(Mailers::DeviseNotificationJob)
  end

  it "enqueues nothing for an unregistered event" do
    expect { described_class.call(event: "unknown.event", foo: "bar") }
      .not_to have_enqueued_job
  end

  it "returns a successful result" do
    result = described_class.call(event: "unknown.event")
    expect(result).to be_success
  end
end
