# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemoteResources::UpsertService, type: :service do
  let(:project) { create(:project) }
  let(:resource) { project.remote_resources.new }

  it "creates with credentials JSON" do
    result = described_class.call(
      remote_resource: resource,
      attributes: { name: "GH", kind: "api_key", credentials_json: '{"token":"abc"}' },
    )
    expect(result).to be_success
    expect(JSON.parse(resource.reload.credentials)).to eq({ "token" => "abc" })
  end

  it "skips credential update when blank" do
    create(:remote_resource, project: project, name: "X", kind: "api_key").tap do |r|
      r.credentials = '{"existing":1}'
      r.save!
    end
    existing = project.remote_resources.last
    result = described_class.call(remote_resource: existing, attributes: { name: "Y", kind: "api_key", credentials_json: "" })
    expect(result).to be_success
    expect(JSON.parse(existing.reload.credentials)).to eq({ "existing" => 1 })
  end

  it "fails on bad JSON" do
    result = described_class.call(remote_resource: resource, attributes: { name: "x", kind: "api_key", credentials_json: "{bad" })
    expect(result).to be_failure
    expect(result.error.errors[:credentials]).to be_present
  end
end
