# frozen_string_literal: true

require "rails_helper"

RSpec.describe Technology, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:project_technologies).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:projects).through(:project_technologies) }
  end

  describe "validations" do
    subject { build(:technology) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
  end
end
