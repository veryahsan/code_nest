# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::DispatchBatchJob, type: :job do
  it "is routed to the mailers queue" do
    expect(described_class.new.queue_name).to eq("mailers")
  end

  it "delegates to the dispatch service" do
    allow(Mailers::DispatchBatchService).to receive(:call)

    described_class.new.perform

    expect(Mailers::DispatchBatchService).to have_received(:call)
  end
end
