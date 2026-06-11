# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::PublishService, type: :service do
  it "routes email-only events to Mailers::DeliveryJob with the event name" do
    user       = create(:user)
    invitation = create(:invitation)
    clear_enqueued_jobs

    expect { described_class.call(event: "user.signed_up", user: user) }
      .to have_enqueued_job(Mailers::DeliveryJob).with(event: "user.signed_up", user: user)

    expect { described_class.call(event: "invitation.created", invitation: invitation) }
      .to have_enqueued_job(Mailers::DeliveryJob).with(event: "invitation.created", invitation: invitation)
  end

  it "routes message.created to Notifications::DeliveryJob only" do
    message = create(:message)
    clear_enqueued_jobs

    expect { described_class.call(event: "message.created", message: message) }
      .to have_enqueued_job(Notifications::DeliveryJob).with(event: "message.created", message: message)

    expect(Mailers::DeliveryJob).not_to have_been_enqueued
  end

  it "routes devise.notification to Mailers::DeliveryJob" do
    user = create(:user)
    clear_enqueued_jobs

    expect {
      described_class.call(
        event: "devise.notification", user: user, notification: "confirmation_instructions", args: [ "tok", {} ]
      )
    }.to have_enqueued_job(Mailers::DeliveryJob)
  end

  it "fans invitation.accepted out to both the email and notification channels" do
    invitation = create(:invitation)
    clear_enqueued_jobs

    described_class.call(event: "invitation.accepted", invitation: invitation)

    expect(Mailers::DeliveryJob).to have_been_enqueued.with(event: "invitation.accepted", invitation: invitation)
    expect(Notifications::DeliveryJob).to have_been_enqueued.with(event: "invitation.accepted", invitation: invitation)
  end

  it "fans project_membership.created out to both channels" do
    membership = create(:project_membership)
    clear_enqueued_jobs

    described_class.call(event: "project_membership.created", project_membership: membership)

    expect(Mailers::DeliveryJob).to have_been_enqueued
      .with(event: "project_membership.created", project_membership: membership)
    expect(Notifications::DeliveryJob).to have_been_enqueued
      .with(event: "project_membership.created", project_membership: membership)
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
