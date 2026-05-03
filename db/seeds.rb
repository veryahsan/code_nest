# frozen_string_literal: true

# Heavy fixtures for local development only. Idempotent: safe to run repeatedly.
if Rails.env.development?
  DEV_PASSWORD = "password12345"

  module DevSeeds
    module_function

    def ensure_user(email:, organisation: nil, super_admin: false, org_role: :member)
      user = User.find_or_initialize_by(email: email)
      user.password = DEV_PASSWORD
      user.password_confirmation = DEV_PASSWORD
      user.super_admin = super_admin
      if super_admin
        user.organisation = nil
      else
        user.organisation = organisation
        user.org_role = org_role
      end
      # Dev fixtures bypass the email-confirmation gate so all sample logins work
      # immediately. Real sign-ups still go through the Devise confirmation flow.
      user.skip_confirmation! if user.new_record? && user.respond_to?(:skip_confirmation!)
      user.save!
      user
    end

    def ensure_team(organisation:, name:, slug:)
      Team.find_or_create_by!(organisation_id: organisation.id, slug: slug) do |t|
        t.name = name
      end
    end

    def ensure_project(organisation:, name:, slug:, team: nil, description: nil)
      project = Project.find_or_initialize_by(organisation_id: organisation.id, slug: slug)
      project.name = name
      project.team = team
      project.description = description
      project.save!
      project
    end

    def ensure_language(name:, code:)
      Language.find_or_create_by!(code: code) { |l| l.name = name }
    end

    def ensure_technology(name:, slug:)
      Technology.find_or_create_by!(slug: slug) { |t| t.name = name }
    end

    def ensure_membership(user:, team:)
      TeamMembership.find_or_create_by!(user_id: user.id, team_id: team.id)
    end

    def ensure_employee(user:, organisation:, display_name:, job_title: nil, manager: nil)
      employee = Employee.find_or_initialize_by(user_id: user.id)
      employee.organisation = organisation
      employee.display_name = display_name
      employee.job_title = job_title
      employee.manager = manager
      employee.save!
      employee
    end

    # Pending invitations use a partial unique index; match pending rows only so re-seeding stays stable
    # after someone accepts an invite with the same email.
    def ensure_pending_invitation(organisation:, email:, invited_by:, org_role:, expires_at: nil)
      organisation.invitations.pending.find_by(email: email) ||
        Invitation.create!(
          organisation: organisation,
          email: email,
          invited_by: invited_by,
          org_role: org_role,
          expires_at: expires_at,
        )
    end

    def ensure_accepted_invitation(organisation:, email:, invited_by:, org_role: :member, accepted_at:)
      return if organisation.invitations.where.not(accepted_at: nil).exists?(email: email)

      Invitation.create!(
        organisation: organisation,
        email: email,
        invited_by: invited_by,
        org_role: org_role,
        expires_at: nil,
        accepted_at: accepted_at,
      )
    end
  end

  extend DevSeeds

  puts "Seeding development database…"

  # --- Reference data (Languages & Technologies) ---
  lang_en = ensure_language(name: "English", code: "en")
  lang_ru = ensure_language(name: "Russian", code: "ru")
  lang_ts = ensure_language(name: "TypeScript", code: "typescript")

  tech_rails = ensure_technology(name: "Ruby on Rails", slug: "ruby-on-rails")
  tech_hotwire = ensure_technology(name: "Hotwire", slug: "hotwire")
  tech_pg = ensure_technology(name: "PostgreSQL", slug: "postgresql")
  tech_python = ensure_technology(name: "Python", slug: "python")

  # --- Organisations (multi-tenant roots) ---
  org_acme = Organisation.find_or_create_by!(slug: "acme") { |o| o.name = "Acme Corporation" }
  org_globex = Organisation.find_or_create_by!(slug: "globex") { |o| o.name = "Globex Industries" }
  org_startup = Organisation.find_or_create_by!(slug: "startup-labs") { |o| o.name = "Startup Labs" }

  # --- Users: platform super admin + per-org roles ---
  ensure_user(email: "platform@codenest.dev", super_admin: true)

  alice = ensure_user(email: "alice@acme.dev", organisation: org_acme, org_role: :admin)
  bob = ensure_user(email: "bob@acme.dev", organisation: org_acme, org_role: :member)
  carol = ensure_user(email: "carol@acme.dev", organisation: org_acme, org_role: :member) # no team / no employee (optional profile)
  _dave = ensure_user(email: "dave@acme.dev", organisation: org_acme, org_role: :member)

  grace = ensure_user(email: "grace@globex.dev", organisation: org_globex, org_role: :admin)
  henry = ensure_user(email: "henry@globex.dev", organisation: org_globex, org_role: :member)

  ensure_user(email: "solo@startup-labs.dev", organisation: org_startup, org_role: :admin)

  # --- Teams & memberships ---
  team_eng = ensure_team(organisation: org_acme, name: "Engineering", slug: "engineering")
  team_product = ensure_team(organisation: org_acme, name: "Product", slug: "product")
  team_globex_core = ensure_team(organisation: org_globex, name: "Core", slug: "core")

  ensure_membership(user: alice, team: team_eng)
  ensure_membership(user: bob, team: team_eng)
  ensure_membership(user: bob, team: team_product)
  ensure_membership(user: carol, team: team_product)
  ensure_membership(user: _dave, team: team_eng)
  ensure_membership(user: grace, team: team_globex_core)
  ensure_membership(user: henry, team: team_globex_core)

  # --- Employees (hierarchy + standalone); Carol deliberately has no Employee row ---
  lead = ensure_employee(
    user: alice,
    organisation: org_acme,
    display_name: "Alice Acme",
    job_title: "Head of Engineering",
  )
  ensure_employee(
    user: bob,
    organisation: org_acme,
    display_name: "Bob Builder",
    job_title: "Senior Developer",
    manager: lead,
  )
  ensure_employee(
    user: grace,
    organisation: org_globex,
    display_name: "Grace Globex",
    job_title: "CTO",
  )
  # Henry: in a team but no employee record (optional HR profile)

  # --- Projects (with/without team; languages & technologies) ---
  proj_phoenix = ensure_project(
    organisation: org_acme,
    name: "Phoenix",
    slug: "phoenix",
    team: team_eng,
    description: "Main customer app — team-scoped, stack-heavy.",
  )
  proj_internal = ensure_project(
    organisation: org_acme,
    name: "Internal Tools",
    slug: "internal-tools",
    team: nil,
    description: "Org-wide utilities without a owning team.",
  )
  proj_legacy = ensure_project(
    organisation: org_globex,
    name: "Legacy Monolith",
    slug: "legacy-monolith",
    team: team_globex_core,
    description: "Older stack maintained by Core.",
  )
  ensure_project(
    organisation: org_startup,
    name: "MVP",
    slug: "mvp",
    team: nil,
    description: "Solo-founder project; org has no teams.",
  )

  ProjectLanguage.find_or_create_by!(project_id: proj_phoenix.id, language_id: lang_en.id)
  ProjectLanguage.find_or_create_by!(project_id: proj_phoenix.id, language_id: lang_ts.id)
  ProjectTechnology.find_or_create_by!(project_id: proj_phoenix.id, technology_id: tech_rails.id)
  ProjectTechnology.find_or_create_by!(project_id: proj_phoenix.id, technology_id: tech_hotwire.id)
  ProjectTechnology.find_or_create_by!(project_id: proj_phoenix.id, technology_id: tech_pg.id)

  ProjectLanguage.find_or_create_by!(project_id: proj_internal.id, language_id: lang_ru.id)
  ProjectTechnology.find_or_create_by!(project_id: proj_internal.id, technology_id: tech_python.id)

  # --- Remote resources (encrypted credentials when LOCKBOX_MASTER_KEY is set) ---
  rr = RemoteResource.find_or_initialize_by(project_id: proj_phoenix.id, name: "Payments API")
  rr.kind = "api_key"
  rr.url = "https://api.example.com/v1"
  if Lockbox.master_key.present?
    rr.credentials = JSON.generate("api_key" => "sk_dev_example_only", "region" => "eu-west-1")
  end
  rr.save!

  rr_bare = RemoteResource.find_or_initialize_by(project_id: proj_legacy.id, name: "On-prem broker")
  rr_bare.kind = "ssh"
  rr_bare.url = ""
  rr_bare.save!

  # --- Project documents ---
  ProjectDocument.find_or_create_by!(project_id: proj_phoenix.id, title: "Architecture overview") do |d|
    d.url = "https://docs.example.com/phoenix/architecture"
    d.external_id = "DOC-PHX-001"
    d.metadata = { "kind" => "notion", "version" => 1 }
  end
  ProjectDocument.find_or_create_by!(project_id: proj_internal.id, title: "Runbook (no URL yet)") do |d|
    d.url = ""
    d.metadata = {}
  end

  # --- Invitations (pending / expiry / accepted / platform inviter / no inviter) ---
  platform_user = User.find_by!(email: "platform@codenest.dev")

  ensure_pending_invitation(
    organisation: org_acme,
    email: "pending-member@example.com",
    invited_by: alice,
    org_role: :member,
    expires_at: nil,
  )

  ensure_pending_invitation(
    organisation: org_acme,
    email: "pending-admin@example.com",
    invited_by: alice,
    org_role: :admin,
    expires_at: 90.days.from_now,
  )

  ensure_pending_invitation(
    organisation: org_globex,
    email: "platform-invited@globex.dev",
    invited_by: platform_user,
    org_role: :member,
    expires_at: 30.days.from_now,
  )

  ensure_pending_invitation(
    organisation: org_startup,
    email: "open-invite@example.com",
    invited_by: nil,
    org_role: :member,
    expires_at: 14.days.from_now,
  )

  ensure_accepted_invitation(
    organisation: org_globex,
    email: "former-candidate@globex.dev",
    invited_by: grace,
    org_role: :member,
    accepted_at: 2.months.ago,
  )

  puts "Done. Dev logins (password for all: #{DEV_PASSWORD}):"
  puts "  Super admin: platform@codenest.dev"
  puts "  Acme admin:  alice@acme.dev"
  puts "  Globex admin: grace@globex.dev"
  puts "  Startup admin: solo@startup-labs.dev"
else
  Rails.logger.info { "db/seeds.rb: development fixtures skipped (#{Rails.env})." }
end
