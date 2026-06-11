# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:commentable) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:comment) }

    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(5_000) }
  end

  describe "commentable" do
    it "can be attached to an issue" do
      issue = create(:issue)
      comment = create(:comment, commentable: issue)

      expect(comment.commentable).to eq(issue)
      expect(issue.comments).to include(comment)
    end

    it "can be attached to a project" do
      project = create(:project)
      comment = create(:comment, commentable: project)

      expect(comment.commentable).to eq(project)
      expect(project.comments).to include(comment)
    end
  end

  describe "reactions" do
    it "is reactable like a message" do
      comment = create(:comment)
      reaction = create(:reaction, reactable: comment, kind: :like)

      expect(comment.reactions).to include(reaction)
    end

    it "destroys its reactions when destroyed" do
      comment = create(:comment)
      create(:reaction, reactable: comment, kind: :like)

      expect { comment.destroy }.to change(Reaction, :count).by(-1)
    end
  end
end
