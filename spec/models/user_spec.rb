# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:project_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:projects).through(:project_memberships) }
    it { is_expected.to have_one(:employee).dependent(:destroy) }
    it { is_expected.to have_many(:sent_invitations).dependent(:nullify) }
    it { is_expected.to have_many(:conversation_participants).dependent(:destroy) }
    it { is_expected.to have_many(:conversations).through(:conversation_participants) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
    it { is_expected.to have_one_attached(:avatar) }

    it "associates at most one organisation" do
      org = create(:organisation)
      user = create(:user, organisation: org)
      expect(user.organisation).to eq(org)
      expect(org.users).to include(user)
    end
  end

  describe "validations" do
    it "allows non-super-admin users to exist without an organisation" do
      user = build(:user, :without_organisation)
      expect(user).to be_valid
    end

    it "allows no organisation for platform super admins" do
      user = build(:user, :super_admin)
      expect(user).to be_valid
    end

    it "does not allow an organisation on super admins" do
      org = create(:organisation)
      user = build(:user, :super_admin)
      user.organisation = org
      expect(user).not_to be_valid
      expect(user.errors[:organisation_id]).to be_present
    end
  end

  describe "avatar" do
    let(:user) { create(:user) }

    it "accepts a valid JPEG attachment" do
      user.avatar.attach(
        io: StringIO.new("fake-jpeg-data"),
        filename: "photo.jpg",
        content_type: "image/jpeg"
      )
      expect(user).to be_valid
    end

    it "rejects a non-image content type" do
      user.avatar.attach(
        io: StringIO.new("fake-pdf-data"),
        filename: "doc.pdf",
        content_type: "application/pdf"
      )
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to be_present
    end

    it "rejects files larger than 5 MB" do
      user.avatar.attach(
        io: StringIO.new("x" * (5.megabytes + 1)),
        filename: "big.png",
        content_type: "image/png"
      )
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to be_present
    end
  end

  describe "roles" do
    it "defaults to member" do
      expect(build(:user).org_member?).to be true
    end

    it "organisation_admin? reflects org admin role" do
      expect(build(:user).organisation_admin?).to be false
      expect(build(:user, :organisation_admin).organisation_admin?).to be true
    end
  end

  describe "project membership helpers" do
    it "#member_of_project? and #lead_for_project? reflect membership" do
      project = create(:project)
      user = create(:user, organisation: project.organisation)
      other = create(:user, organisation: project.organisation)
      create(:project_membership, :lead, project: project, user: user)

      expect(user.member_of_project?(project)).to be true
      expect(user.lead_for_project?(project)).to be true
      expect(other.member_of_project?(project)).to be false
      expect(other.lead_for_project?(project)).to be false
    end
  end

  describe "confirmable" do
    it "includes Devise's confirmable module" do
      expect(described_class.devise_modules).to include(:confirmable)
    end

    it "creates new accounts in an unconfirmed state" do
      user = described_class.create!(
        email: "newbie@example.com",
        password: "password12345",
        password_confirmation: "password12345",
      )

      expect(user.confirmed?).to be false
      expect(user.confirmation_token).to be_present
      expect(user.active_for_authentication?).to be false
      expect(user.inactive_message).to eq(:unconfirmed)
    end

    it "auto-confirms platform super admins on creation" do
      user = described_class.create!(
        email: "platform@example.com",
        password: "password12345",
        password_confirmation: "password12345",
        super_admin: true,
      )

      expect(user.confirmed?).to be true
      expect(user.active_for_authentication?).to be true
    end
  end

  describe "#sso_only?" do
    it "is false for a brand-new in-memory user" do
      expect(build(:user).sso_only?).to be false
    end

    it "is false for a persisted local-password user with no identities" do
      user = create(:user)
      expect(user.sso_only?).to be false
    end

    it "is true once any identity is linked" do
      user = create(:user)
      create(:identity, user: user)
      expect(user.reload.sso_only?).to be true
    end
  end

  describe "#password_required?" do
    # `:validatable` calls this on every save. We only ever want to short-circuit
    # for SSO users — local-password sign-ups must keep being validated.
    it "stays true for a brand-new in-memory user (sign-up still requires a password)" do
      expect(build(:user).password_required?).to be true
    end

    it "stays true for a persisted local-password user" do
      expect(create(:user).password_required?).to be true
    end

    it "is false once the persisted user has at least one identity" do
      user = create(:user)
      create(:identity, user: user)
      expect(user.reload.password_required?).to be false
    end
  end

  describe "#enqueue_welcome_email (after_create_commit trigger)" do
    # Like #after_confirmation, the callback is a thin trigger that delegates
    # to the service. The super-admin skip lives in the service and is covered
    # by spec/services/mailers/enqueue_welcome_email_service_spec.rb.
    it "delegates to Mailers::EnqueueWelcomeEmailService" do
      user = build(:user)
      allow(Mailers::EnqueueWelcomeEmailService).to receive(:call)

      user.send(:enqueue_welcome_email)

      expect(Mailers::EnqueueWelcomeEmailService).to have_received(:call).with(user: user)
    end
  end

  describe "#after_confirmation (Devise hook)" do
    # The hook is intentionally a thin trigger: it delegates to the facade
    # without doing any branching of its own. The facade owns the policy
    # and is covered exhaustively by spec/facades/users/post_confirmation_facade_spec.rb.
    it "delegates to Users::PostConfirmationFacade" do
      user = described_class.create!(
        email: "trigger@example.com",
        password: "password12345",
        password_confirmation: "password12345",
      )
      allow(Users::PostConfirmationFacade).to receive(:call)

      user.after_confirmation

      expect(Users::PostConfirmationFacade).to have_received(:call).with(user: user)
    end
  end
end
