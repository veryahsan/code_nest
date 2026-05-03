# frozen_string_literal: true

# Returns the oldest organisation whose roster already contains a member
# whose email ends in the same `@domain` as the supplied email, or nil.
# Used by Users::PostConfirmationFacade to attach freshly-confirmed users
# to their company's tenant without an explicit invitation.
#
# This service never raises and never writes — it always succeeds with an
# Organisation or nil.
#
# == Public-domain denylist
# Domains in PUBLIC_EMAIL_DOMAINS are excluded from the auto-join lookup.
# They cover the global free-mail providers where a domain match would
# incorrectly collapse unrelated personal accounts into the same tenant.
#
# Operators can extend the list at deploy time without a code change by
# setting the `PUBLIC_EMAIL_DOMAINS_EXTRA` environment variable to a
# comma-separated list of additional domains:
#
#   PUBLIC_EMAIL_DOMAINS_EXTRA=protonmail.com,icloud.com
#
# See docs/onboarding_flow.md for the full design rationale.
module Organisations
  class FindByEmailDomainService < ApplicationService
    # Major free-mail / consumer providers. Lowercase, no leading @.
    # Source: curated from https://github.com/disposable-email-domains/disposable-email-domains
    # and common knowledge; kept intentionally conservative so legitimate
    # corporate use of e.g. Fastmail doesn't get blocked.
    PUBLIC_EMAIL_DOMAINS = Set.new(%w[
      gmail.com
      googlemail.com
      yahoo.com
      yahoo.co.uk
      yahoo.co.in
      yahoo.com.au
      yahoo.com.br
      yahoo.ca
      ymail.com
      rocketmail.com
      outlook.com
      outlook.co.uk
      outlook.in
      hotmail.com
      hotmail.co.uk
      hotmail.fr
      hotmail.de
      live.com
      live.co.uk
      live.fr
      msn.com
      icloud.com
      me.com
      mac.com
      aol.com
      aim.com
      proton.me
      protonmail.com
      protonmail.ch
      mail.ru
      yandex.ru
      yandex.com
      inbox.ru
      list.ru
      bk.ru
      internet.ru
      gmx.com
      gmx.net
      gmx.de
      gmx.at
      gmx.us
      web.de
      freenet.de
      zohomail.com
      zoho.com
    ]).freeze

    # Runtime-configurable extra blocked domains (comma-separated env var).
    EXTRA_DOMAINS = begin
      raw = ENV.fetch("PUBLIC_EMAIL_DOMAINS_EXTRA", "")
      Set.new(raw.split(",").map { |d| d.strip.downcase }.reject(&:blank?))
    end.freeze

    def initialize(email:)
      @email = email
    end

    def call
      success(lookup)
    end

    private

    def lookup
      domain = extract_domain
      return nil if domain.blank?
      return nil if public_domain?(domain)

      pattern = "%@#{Organisation.sanitize_sql_like(domain)}"
      Organisation
        .joins(:users)
        .where("LOWER(users.email) LIKE ?", pattern)
        .order(:created_at)
        .first
    end

    def extract_domain
      @email.to_s.split("@", 2).last.to_s.downcase.strip
    end

    def public_domain?(domain)
      PUBLIC_EMAIL_DOMAINS.include?(domain) || EXTRA_DOMAINS.include?(domain)
    end
  end
end
