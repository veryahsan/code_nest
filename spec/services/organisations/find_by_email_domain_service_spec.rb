# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organisations::FindByEmailDomainService, type: :service do
  describe ".call" do
    let!(:acme) { create(:organisation, name: "Acme", slug: "acme-fbed-1") }
    let!(:globex) { create(:organisation, name: "Globex", slug: "globex-fbed-1") }

    before do
      create(:user, organisation: acme, email: "alice@acme.dev")
      create(:user, organisation: globex, email: "grace@globex.dev")
    end

    it "returns the organisation that already has a member of the same domain" do
      result = described_class.call(email: "bob@acme.dev")

      expect(result).to be_success
      expect(result.value).to eq(acme)
    end

    it "is case-insensitive on the supplied email" do
      expect(described_class.call(email: "BOB@ACME.DEV").value).to eq(acme)
    end

    it "returns nil when no member shares the domain" do
      expect(described_class.call(email: "solo@nobody.example").value).to be_nil
    end

    it "returns nil for malformed input" do
      expect(described_class.call(email: "not-an-email").value).to be_nil
      expect(described_class.call(email: "").value).to be_nil
      expect(described_class.call(email: nil).value).to be_nil
    end

    it "picks the oldest organisation when multiple share the domain" do
      older = create(:organisation, name: "Older", slug: "older-fbed-1", created_at: 2.years.ago)
      create(:user, organisation: older, email: "first@shared.example")
      newer = create(:organisation, name: "Newer", slug: "newer-fbed-1", created_at: 1.year.ago)
      create(:user, organisation: newer, email: "second@shared.example")

      expect(described_class.call(email: "third@shared.example").value).to eq(older)
    end

    # ── Public-domain denylist ─────────────────────────────────────────────
    context "when the email uses a public free-mail domain" do
      before do
        # Seed an org as if someone had previously signed up with a free-mail
        # address. Without the denylist, a second Gmail user would incorrectly
        # join this tenant.
        create(:user, organisation: acme, email: "personal@gmail.com")
      end

      it "returns nil for gmail.com so users are not auto-joined" do
        expect(described_class.call(email: "other@gmail.com").value).to be_nil
      end

      it "returns nil for every built-in public domain" do
        sample_domains = %w[
          gmail.com googlemail.com
          yahoo.com ymail.com
          outlook.com hotmail.com live.com msn.com
          icloud.com me.com mac.com
          aol.com
          proton.me protonmail.com
          mail.ru yandex.ru yandex.com
          gmx.com gmx.net web.de
          zohomail.com zoho.com
        ]
        sample_domains.each do |domain|
          result = described_class.call(email: "user@#{domain}")
          expect(result.value).to be_nil,
            "expected nil for #{domain} but got #{result.value.inspect}"
        end
      end

      it "still matches when the domain is corporate (not in the denylist)" do
        expect(described_class.call(email: "bob@acme.dev").value).to eq(acme)
      end
    end

    # ── Operator-configurable extra denylist ──────────────────────────────
    context "when PUBLIC_EMAIL_DOMAINS_EXTRA is set" do
      before { stub_extra_domains("customfree.example,anotherfreeprovider.io") }

      it "blocks domains from the extra list" do
        create(:user, organisation: acme, email: "person@customfree.example")

        expect(described_class.call(email: "other@customfree.example").value).to be_nil
        expect(described_class.call(email: "user@anotherfreeprovider.io").value).to be_nil
      end

      it "still allows domains not in either list" do
        expect(described_class.call(email: "bob@acme.dev").value).to eq(acme)
      end
    end
  end

  private

  # Temporarily overrides EXTRA_DOMAINS by mutating the frozen Set.
  # We swap the constant on the service class for the duration of the example.
  def stub_extra_domains(csv)
    domains = Set.new(csv.split(",").map { |d| d.strip.downcase })
    stub_const(
      "#{described_class}::EXTRA_DOMAINS",
      domains.freeze,
    )
  end
end
