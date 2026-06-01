# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::EnqueueWelcomeEmailService, type: :service do
  let(:outbox) { class_double(Mailers::Outbox, enqueue: nil) }

  it "enqueues a low-priority welcome email" do
    user = create(:user)

    result = described_class.call(user: user, outbox: outbox)

    expect(result).to be_success
    expect(outbox).to have_received(:enqueue).with(WelcomeMailer, :welcome, user, priority: :low)
  end

  it "skips super admins (provisioned out-of-band)" do
    user = create(:user, :super_admin)

    result = described_class.call(user: user, outbox: outbox)

    expect(result).to be_success
    expect(outbox).not_to have_received(:enqueue)
  end
end
