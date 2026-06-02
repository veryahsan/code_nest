# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::WelcomeEmailJob, type: :job do
  it "is routed to the mailers queue" do
    expect(described_class.new.queue_name).to eq("mailers")
  end

  it "delegates to Mailers::EnqueueWelcomeEmailService" do
    user = create(:user)
    allow(Mailers::EnqueueWelcomeEmailService).to receive(:call)

    described_class.new.perform(user: user)

    expect(Mailers::EnqueueWelcomeEmailService).to have_received(:call).with(user: user)
  end
end
