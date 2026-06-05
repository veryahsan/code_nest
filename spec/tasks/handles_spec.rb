# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "handles:backfill", type: :task do
  before(:all) do
    Rake.application.rake_require("tasks/handles", [Rails.root.join("lib").to_s])
    Rake::Task.define_task(:environment)
  end

  let(:org) { create(:organisation) }

  def run_task
    Rake::Task["handles:backfill"].reenable
    Rake::Task["handles:backfill"].invoke
  end

  it "backfills employees that are missing a handle" do
    employee = create(:employee, organisation: org)
    employee.update_column(:handle, nil)

    run_task

    expect(employee.reload.handle).to be_present
  end

  it "leaves existing handles untouched" do
    employee = create(:employee, organisation: org, handle: "keepme")

    run_task

    expect(employee.reload.handle).to eq("keepme")
  end

  it "is idempotent across repeated runs" do
    employee = create(:employee, organisation: org)
    employee.update_column(:handle, nil)

    run_task
    first = employee.reload.handle
    run_task

    expect(employee.reload.handle).to eq(first)
  end

  it "generates handles unique within the organisation" do
    a = create(:user, organisation: org, email: "sam@example.com")
    b = create(:user, organisation: org, email: "sam@other.com")
    emp_a = create(:employee, user: a, organisation: org)
    emp_b = create(:employee, user: b, organisation: org)
    [emp_a, emp_b].each { |e| e.update_column(:handle, nil) }

    run_task

    expect(emp_a.reload.handle).not_to eq(emp_b.reload.handle)
  end
end
