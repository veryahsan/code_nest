# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectDocuments::UpsertService, type: :service do
  let(:project) { create(:project) }
  let(:document) { project.project_documents.new }

  it "creates a document with parsed JSON metadata" do
    result = described_class.call(
      document: document,
      attributes: { title: "Runbook", url: "https://example.com", metadata: '{"version":1}' },
    )
    expect(result).to be_success
    expect(result.value.metadata).to eq({ "version" => 1 })
  end

  it "treats blank metadata as empty hash" do
    result = described_class.call(document: document, attributes: { title: "Runbook" })
    expect(result.value.metadata).to eq({})
  end

  it "fails on invalid JSON" do
    result = described_class.call(document: document, attributes: { title: "Runbook", metadata: "not-json" })
    expect(result).to be_failure
    expect(result.error.errors[:metadata]).to be_present
  end

  it "fails on JSON that is not an object" do
    result = described_class.call(document: document, attributes: { title: "X", metadata: "[1,2,3]" })
    expect(result).to be_failure
  end
end
