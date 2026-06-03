# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::WelcomeEmailJob, type: :job do
  it "is routed to the mailers queue" do
    expect(described_class.new.queue_name).to eq("mailers")
  end

  it "enqueues the welcome email onto the outbox at low priority" do
    allow(Mailers::Outbox).to receive(:enqueue)
    user = create(:user)

    described_class.new.perform(user: user)

    expect(Mailers::Outbox).to have_received(:enqueue).with(
      WelcomeMailer, :welcome, user, priority: :low
    )
  end

  it "skips super admins (provisioned out-of-band)" do
    allow(Mailers::Outbox).to receive(:enqueue)
    user = create(:user, :super_admin)

    described_class.new.perform(user: user)

    expect(Mailers::Outbox).not_to have_received(:enqueue)
  end
end
