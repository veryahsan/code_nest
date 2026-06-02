# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::InvitationEmailJob, type: :job do
  it "is routed to the mailers queue" do
    expect(described_class.new.queue_name).to eq("mailers")
  end

  it "enqueues the invitation email onto the outbox at default priority" do
    allow(Mailers::Outbox).to receive(:enqueue)
    invitation = create(:invitation)

    described_class.new.perform(invitation: invitation)

    expect(Mailers::Outbox).to have_received(:enqueue).with(
      InvitationMailer, :invite, invitation, priority: :default
    )
  end
end
