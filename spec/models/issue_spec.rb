# frozen_string_literal: true

require "rails_helper"

RSpec.describe Issue, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:assignee).class_name("User").optional }
    it { is_expected.to belong_to(:assignor).class_name("User").optional }
    it { is_expected.to have_many(:comments).dependent(:destroy) }

    it "has many attachments" do
      issue = create(:issue)
      issue.attachments.attach(
        io: StringIO.new("hello"), filename: "note.txt", content_type: "text/plain"
      )

      expect(issue.attachments).to be_attached
      expect(issue.attachments.count).to eq(1)
    end
  end

  describe "validations" do
    subject { build(:issue) }

    it { is_expected.to validate_presence_of(:summary) }
    it { is_expected.to validate_length_of(:summary).is_at_most(255) }

    it "rejects an assignee from another organisation" do
      project = create(:project)
      foreign = create(:user, organisation: create(:organisation))
      issue = build(:issue, project: project, assignee: foreign)

      expect(issue).not_to be_valid
      expect(issue.errors[:assignee]).to be_present
    end

    it "rejects an assignor from another organisation" do
      project = create(:project)
      foreign = create(:user, organisation: create(:organisation))
      issue = build(:issue, project: project, assignor: foreign)

      expect(issue).not_to be_valid
      expect(issue.errors[:assignor]).to be_present
    end

    it "accepts an assignee from the project's organisation" do
      project = create(:project)
      member = create(:user, organisation: project.organisation)
      issue = build(:issue, project: project, assignee: member)

      expect(issue).to be_valid
    end

    it "rejects blank summary after normalization" do
      issue = build(:issue, summary: "   ")
      expect(issue).not_to be_valid
      expect(issue.errors[:summary]).to be_present
    end

    it "requires number and issue_key when sequence assignment is skipped" do
      issue = build(:issue)
      allow(issue).to receive(:assign_sequence_and_key)

      expect(issue).not_to be_valid
      expect(issue.errors[:number]).to be_present
      expect(issue.errors[:issue_key]).to be_present
    end

    it "requires number to be a positive integer" do
      issue = create(:issue)
      issue.number = 0

      expect(issue).not_to be_valid
      expect(issue.errors[:number]).to be_present
    end

    it "enforces unique number per project" do
      project = create(:project)
      create(:issue, project: project, summary: "One")
      duplicate = build(:issue, project: project, summary: "Two")
      allow(duplicate).to receive(:assign_sequence_and_key)
      duplicate.number = 1
      duplicate.issue_key = "DUP-2"

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:number]).to be_present
    end

    it "enforces unique issue_key globally" do
      existing = create(:issue)
      duplicate = build(:issue, project: create(:project), summary: "Duplicate key")
      allow(duplicate).to receive(:assign_sequence_and_key)
      duplicate.number = 99
      duplicate.issue_key = existing.issue_key

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:issue_key]).to be_present
    end
  end

  describe "enums" do
    it "accepts valid enum values" do
      issue = build(:issue, issue_type: :bug, status: :in_progress, priority: :high)
      expect(issue).to be_valid
      expect(issue.issue_type_bug?).to be true
      expect(issue.status_in_progress?).to be true
      expect(issue.priority_high?).to be true
    end
  end

  describe "callbacks" do
    it "assigns sequential numbers and issue keys per project" do
      project = create(:project, slug: "my-app")
      first = create(:issue, project: project, summary: "First")
      second = create(:issue, project: project, summary: "Second")

      expect(first.number).to eq(1)
      expect(first.issue_key).to eq("MYAPP-1")
      expect(second.number).to eq(2)
      expect(second.issue_key).to eq("MYAPP-2")
    end

    it "strips whitespace from summary" do
      issue = create(:issue, summary: "  Trim me  ")
      expect(issue.summary).to eq("Trim me")
    end

    it "touches the parent project on update" do
      project = create(:project)
      issue = create(:issue, project: project)

      expect { issue.update!(summary: "Updated summary") }
        .to change { project.reload.updated_at }
    end
  end

  describe "event publishing" do
    let(:project) { create(:project) }
    let(:assignee) { create(:user, organisation: project.organisation) }
    let(:assignor) { create(:user, organisation: project.organisation) }

    it "publishes issue.assigned when an assignee is set" do
      issue = create(:issue, project: project)
      allow(Events::PublishService).to receive(:call).and_call_original

      issue.update!(assignee: assignee, assignor: assignor)

      expect(Events::PublishService).to have_received(:call)
        .with(event: "issue.assigned", issue: issue)
    end

    it "does not publish issue.assigned when the assignee did not change" do
      issue = create(:issue, project: project, assignee: assignee, assignor: assignor)
      allow(Events::PublishService).to receive(:call).and_call_original

      issue.update!(summary: "Changed summary")

      expect(Events::PublishService).not_to have_received(:call)
        .with(event: "issue.assigned", issue: issue)
    end

    it "does not publish issue.assigned when the assignee is cleared" do
      issue = create(:issue, project: project, assignee: assignee, assignor: assignor)
      allow(Events::PublishService).to receive(:call).and_call_original

      issue.update!(assignee: nil)

      expect(Events::PublishService).not_to have_received(:call)
        .with(event: "issue.assigned", issue: issue)
    end
  end
end
