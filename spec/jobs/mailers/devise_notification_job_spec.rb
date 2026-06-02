# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::DeviseNotificationJob, type: :job do
  it "is routed to the mailers queue" do
    expect(described_class.new.queue_name).to eq("mailers")
  end

  it "enqueues the Devise notification onto the outbox at high priority" do
    allow(Mailers::Outbox).to receive(:enqueue)

    user = create(:user)
    token = "abc123"

    described_class.new.perform(
      user:         user,
      notification: "confirmation_instructions",
      args:         [token, {}]
    )

    expect(Mailers::Outbox).to have_received(:enqueue).with(
      Devise.mailer,
      :confirmation_instructions,
      user,
      token,
      {},
      priority: :high
    )
  end
end
