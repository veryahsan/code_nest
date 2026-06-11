# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::DeliveryJob, type: :job do
  it "is routed to the mailers queue" do
    expect(described_class.new.queue_name).to eq("mailers")
  end

  it "enqueues the routed mailer invocation onto the outbox" do
    allow(Mailers::Outbox).to receive(:enqueue)
    invitation = create(:invitation)

    described_class.new.perform(event: "invitation.created", invitation: invitation)

    expect(Mailers::Outbox).to have_received(:enqueue).with(
      InvitationMailer, :invite, invitation, priority: :default
    )
  end

  it "enqueues nothing when the route skips (e.g. super admin welcome)" do
    allow(Mailers::Outbox).to receive(:enqueue)
    user = create(:user, :super_admin)

    described_class.new.perform(event: "user.signed_up", user: user)

    expect(Mailers::Outbox).not_to have_received(:enqueue)
  end

  it "enqueues nothing for an event without an email route" do
    allow(Mailers::Outbox).to receive(:enqueue)
    message = create(:message)

    described_class.new.perform(event: "message.created", message: message)

    expect(Mailers::Outbox).not_to have_received(:enqueue)
  end
end
