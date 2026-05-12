# frozen_string_literal: true

require "rails_helper"

RSpec.describe Employees::CreationFacade, type: :facade do
  let(:org) { create(:organisation) }
  let(:user) { create(:user, organisation: org) }

  it "creates an employee linked to the user" do
    result = described_class.call(
      organisation: org,
      attributes: { user_id: user.id, display_name: "Alice", job_title: "CEO" },
    )

    expect(result).to be_success
    expect(result.value).to have_attributes(display_name: "Alice", job_title: "CEO", user: user, organisation: org)
  end

  it "fails when the user belongs to a different organisation" do
    foreign = create(:user, organisation: create(:organisation))
    result = described_class.call(organisation: org, attributes: { user_id: foreign.id })
    expect(result).to be_failure
    expect(result.error.errors[:organisation]).to be_present
  end

  it "fails when no user is supplied" do
    result = described_class.call(organisation: org, attributes: {})
    expect(result).to be_failure
  end
end
