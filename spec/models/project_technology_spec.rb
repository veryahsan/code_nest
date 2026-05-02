# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectTechnology, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:technology) }
  end

  describe "validations" do
    subject { build(:project_technology) }

    it { is_expected.to validate_uniqueness_of(:technology_id).scoped_to(:project_id) }
  end
end
