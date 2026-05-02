# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectLanguage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:language) }
  end

  describe "validations" do
    subject { build(:project_language) }

    it { is_expected.to validate_uniqueness_of(:language_id).scoped_to(:project_id) }
  end
end
