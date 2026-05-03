# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organisation, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:users).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:teams).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:employees).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:invitations).dependent(:destroy) }
    it { is_expected.to have_many(:projects).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject { build(:organisation) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug).ignoring_case_sensitivity }
  end

  # Slug generation and email-domain lookups live in the services layer:
  #   * spec/services/organisations/generate_unique_slug_service_spec.rb
  #   * spec/services/organisations/find_by_email_domain_service_spec.rb
end
