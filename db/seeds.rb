# frozen_string_literal: true

# Heavy fixtures for local development only. Idempotent: safe to run repeatedly.
if Rails.env.development?
  DEV_PASSWORD = "password12345"

  # Deterministic name pools — avoids Faker's runtime randomness while still
  # producing realistic display names across re-runs.
  SEED_FIRST_NAMES = %w[
    Alice Bob Carol Dave Eve Frank Grace Henry Iris Jack Kate Liam Mia Noah Olivia
    Paul Quinn Rose Sam Tina Uma Victor Wendy Xander Yara Zach Ana Ben Cara Dan Ella
    Finn Gina Hugo Isla Jake Kyra Leo Maya Nate Ora Pete Riya Seth Tara Ugo Vera
    Will Xena Yuki Zara Abe Bea Clay Dana Eric Faye Gio Hana Ivan Jana
  ].freeze

  SEED_LAST_NAMES = %w[
    Smith Jones Williams Brown Taylor Davies Evans Wilson Thomas Roberts Johnson Lewis
    Lee Walker Hall Allen Young Hernandez King Wright Scott Green Baker Adams Nelson
    Carter Mitchell Perez Turner Phillips Campbell Parker Edwards Collins Stewart
    Sanchez Morris Rogers Reed Cook Morgan Bell Murphy Bailey Rivera Cooper Richardson
    Cox Howard Ward Torres Peterson Gray Ramirez Watson Brooks Kelly Sanders Price
    Bennett Wood Barnes Ross Henderson Coleman Jenkins Perry Powell Long Patterson
  ].freeze

  SEED_JOB_TITLES = [
    "Software Engineer", "Senior Software Engineer", "Staff Engineer",
    "Engineering Manager", "Principal Engineer", "Technical Lead",
    "Product Manager", "Senior Product Manager", "Associate PM",
    "Data Engineer", "Data Scientist", "ML Engineer",
    "DevOps Engineer", "SRE", "Platform Engineer", "Cloud Architect",
    "QA Engineer", "Senior QA Engineer", "QA Lead", "SDET",
    "Frontend Engineer", "Backend Engineer", "Full-Stack Engineer",
    "iOS Developer", "Android Developer", "Mobile Engineer",
    "Security Engineer", "Solutions Architect", "Systems Architect",
    "UX Designer", "UI Designer", "Product Designer",
    "Business Analyst", "Scrum Master", "Technical Writer", "Developer Advocate",
  ].freeze

  # ── Helper module ───────────────────────────────────────────────────────────
  module DevSeeds
    module_function

    def ensure_user(email:, organisation: nil, super_admin: false, org_role: :member)
      user = User.find_or_initialize_by(email: email)
      user.password              = DEV_PASSWORD
      user.password_confirmation = DEV_PASSWORD
      user.super_admin           = super_admin
      if super_admin
        user.organisation = nil
      else
        user.organisation = organisation
        user.org_role     = org_role
      end
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
      project.name        = name
      project.team        = team
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
      employee              = Employee.find_or_initialize_by(user_id: user.id)
      employee.organisation = organisation
      employee.display_name = display_name
      employee.job_title    = job_title
      employee.manager      = manager
      employee.save!
      employee
    end

    def ensure_pending_invitation(organisation:, email:, invited_by:, org_role:, expires_at: nil)
      organisation.invitations.pending.find_by(email: email) ||
        Invitation.create!(
          organisation: organisation,
          email:        email,
          invited_by:   invited_by,
          org_role:     org_role,
          expires_at:   expires_at,
        )
    end

    def ensure_accepted_invitation(organisation:, email:, invited_by:, org_role: :member, accepted_at:)
      return if organisation.invitations.where.not(accepted_at: nil).exists?(email: email)

      Invitation.create!(
        organisation: organisation,
        email:        email,
        invited_by:   invited_by,
        org_role:     org_role,
        expires_at:   nil,
        accepted_at:  accepted_at,
      )
    end
  end

  extend DevSeeds

  puts "Seeding development database…"

  # ── Programming languages ───────────────────────────────────────────────────
  PROG_LANG_DEFS = [
    { name: "JavaScript",  code: "javascript"  },
    { name: "TypeScript",  code: "typescript"  },
    { name: "Ruby",        code: "ruby"        },
    { name: "Python",      code: "python"      },
    { name: "Go",          code: "go"          },
    { name: "Rust",        code: "rust"        },
    { name: "SQL",         code: "sql"         },
    { name: "C#",          code: "csharp"      },
    { name: "C++",         code: "cpp"         },
    { name: "Java",        code: "java"        },
    { name: "Kotlin",      code: "kotlin"      },
    { name: "Swift",       code: "swift"       },
    { name: "PHP",         code: "php"         },
    { name: "Scala",       code: "scala"       },
    { name: "Elixir",      code: "elixir"      },
    { name: "Dart",        code: "dart"        },
    { name: "R",           code: "r-lang"      },
    { name: "Shell/Bash",  code: "shell"       },
    { name: "HTML/CSS",    code: "html"        },
    { name: "English",     code: "en"          },
    { name: "Russian",     code: "ru"          },
  ].freeze

  # langs["ruby"] => Language record
  langs = PROG_LANG_DEFS.each_with_object({}) do |l, h|
    h[l[:code]] = ensure_language(name: l[:name], code: l[:code])
  end

  # ── Technology stacks ───────────────────────────────────────────────────────
  TECH_DEFS = [
    { name: "Ruby on Rails",   slug: "ruby-on-rails"   },
    { name: "Hotwire",         slug: "hotwire"          },
    { name: "PostgreSQL",      slug: "postgresql"       },
    { name: "React",           slug: "react"            },
    { name: "Vue.js",          slug: "vue-js"           },
    { name: "Next.js",         slug: "next-js"          },
    { name: "Node.js",         slug: "node-js"          },
    { name: "Django",          slug: "django"           },
    { name: "FastAPI",         slug: "fastapi"          },
    { name: "Spring Boot",     slug: "spring-boot"      },
    { name: "Docker",          slug: "docker"           },
    { name: "Kubernetes",      slug: "kubernetes"       },
    { name: "Redis",           slug: "redis"            },
    { name: "MongoDB",         slug: "mongodb"          },
    { name: "Elasticsearch",   slug: "elasticsearch"    },
    { name: "GraphQL",         slug: "graphql"          },
    { name: "gRPC",            slug: "grpc"             },
    { name: "Terraform",       slug: "terraform"        },
    { name: "AWS",             slug: "aws"              },
    { name: "Google Cloud",    slug: "google-cloud"     },
    { name: "Sidekiq",         slug: "sidekiq"          },
    { name: "Apache Kafka",    slug: "apache-kafka"     },
    { name: "Prometheus",      slug: "prometheus"       },
    { name: "Tailwind CSS",    slug: "tailwindcss"      },
    { name: "Flutter",         slug: "flutter"          },
    { name: "Python",          slug: "python"           },
  ].freeze

  # techs["ruby-on-rails"] => Technology record
  techs = TECH_DEFS.each_with_object({}) do |t, h|
    h[t[:slug]] = ensure_technology(name: t[:name], slug: t[:slug])
  end

  # ── Organisations ───────────────────────────────────────────────────────────
  org_acme    = Organisation.find_or_create_by!(slug: "acme")         { |o| o.name = "Acme Corporation"  }
  org_globex  = Organisation.find_or_create_by!(slug: "globex")       { |o| o.name = "Globex Industries" }
  org_startup = Organisation.find_or_create_by!(slug: "startup-labs") { |o| o.name = "Startup Labs"      }

  # ── Platform super admin ────────────────────────────────────────────────────
  ensure_user(email: "platform@codenest.dev", super_admin: true)

  # ── Per-organisation bulk setup ─────────────────────────────────────────────
  #
  # Each org gets:
  #   • 50 numbered dev users   (dev001@<domain> … dev050@<domain>)
  #   • 6 teams
  #   • 2 projects per team (12 projects total), each with relevant languages + techs
  #   • 50 employee records (first 6 become team leads; rest report to their lead)
  #   • Team memberships distributed evenly + every 3rd user joins a second team

  ORG_TEAM_DEFS = [
    { name: "Engineering",              slug: "engineering"       },
    { name: "Product",                  slug: "product"           },
    { name: "Data & Analytics",         slug: "data-analytics"    },
    { name: "DevOps & Infrastructure",  slug: "devops"            },
    { name: "Quality Assurance",        slug: "quality-assurance" },
    { name: "Mobile",                   slug: "mobile"            },
  ].freeze

  # project definitions keyed by team slug; slug is interpolated with org prefix
  ORG_PROJECT_DEFS = [
    {
      team_slug:   "engineering",
      name:        "Core Platform",
      slug_suffix: "core-platform",
      desc:        "Primary customer-facing application and API surface.",
      lang_codes:  %w[ruby typescript sql],
      tech_slugs:  %w[ruby-on-rails hotwire postgresql redis sidekiq],
    },
    {
      team_slug:   "engineering",
      name:        "API Gateway",
      slug_suffix: "api-gateway",
      desc:        "Centralised API routing, rate-limiting, and authentication proxy.",
      lang_codes:  %w[go rust sql],
      tech_slugs:  %w[grpc postgresql docker redis],
    },
    {
      team_slug:   "product",
      name:        "Customer Dashboard",
      slug_suffix: "customer-dashboard",
      desc:        "User-facing analytics and reporting dashboard.",
      lang_codes:  %w[typescript javascript html],
      tech_slugs:  %w[react next-js tailwindcss graphql],
    },
    {
      team_slug:   "product",
      name:        "Admin Console",
      slug_suffix: "admin-console",
      desc:        "Internal operations tooling for support and ops teams.",
      lang_codes:  %w[ruby typescript html],
      tech_slugs:  %w[ruby-on-rails hotwire tailwindcss postgresql],
    },
    {
      team_slug:   "data-analytics",
      name:        "Analytics Pipeline",
      slug_suffix: "analytics-pipeline",
      desc:        "Real-time event ingestion, transformation, and warehousing.",
      lang_codes:  %w[python sql scala],
      tech_slugs:  %w[apache-kafka postgresql elasticsearch google-cloud],
    },
    {
      team_slug:   "data-analytics",
      name:        "ML Platform",
      slug_suffix: "ml-platform",
      desc:        "Model training, evaluation, and serving infrastructure.",
      lang_codes:  %w[python r-lang sql],
      tech_slugs:  %w[docker kubernetes google-cloud mongodb],
    },
    {
      team_slug:   "devops",
      name:        "CI/CD Platform",
      slug_suffix: "cicd",
      desc:        "Deployment automation, pipeline orchestration, and release tooling.",
      lang_codes:  %w[shell go],
      tech_slugs:  %w[docker kubernetes terraform aws],
    },
    {
      team_slug:   "devops",
      name:        "Observability Stack",
      slug_suffix: "observability",
      desc:        "Metrics, distributed tracing, log aggregation, and alerting.",
      lang_codes:  %w[go shell sql],
      tech_slugs:  %w[prometheus elasticsearch aws docker],
    },
    {
      team_slug:   "quality-assurance",
      name:        "Test Automation Framework",
      slug_suffix: "test-automation",
      desc:        "End-to-end and integration test suite shared across all services.",
      lang_codes:  %w[ruby javascript],
      tech_slugs:  %w[ruby-on-rails node-js docker],
    },
    {
      team_slug:   "quality-assurance",
      name:        "Performance Benchmarks",
      slug_suffix: "perf-benchmarks",
      desc:        "Load, stress, and chaos testing tooling.",
      lang_codes:  %w[go rust shell],
      tech_slugs:  %w[docker kubernetes prometheus],
    },
    {
      team_slug:   "mobile",
      name:        "iOS App",
      slug_suffix: "ios-app",
      desc:        "Native iOS application.",
      lang_codes:  %w[swift],
      tech_slugs:  %w[aws],
    },
    {
      team_slug:   "mobile",
      name:        "Android App",
      slug_suffix: "android-app",
      desc:        "Native Android application.",
      lang_codes:  %w[kotlin java],
      tech_slugs:  %w[aws],
    },
  ].freeze

  [
    { org: org_acme,    domain: "acme.dev",        prefix: "acme"    },
    { org: org_globex,  domain: "globex.dev",       prefix: "globex"  },
    { org: org_startup, domain: "startup-labs.dev", prefix: "startup" },
  ].each do |cfg|
    org    = cfg[:org]
    domain = cfg[:domain]
    prefix = cfg[:prefix]

    puts "  [#{org.name}] users, teams, employees, projects…"

    # ── 50 bulk users ──────────────────────────────────────────────────────
    org_users = (1..50).map do |n|
      ensure_user(
        email:        "dev#{n.to_s.rjust(3, '0')}@#{domain}",
        organisation: org,
        org_role:     :member,
      )
    end

    # ── 6 teams ────────────────────────────────────────────────────────────
    teams = ORG_TEAM_DEFS.map do |t|
      ensure_team(organisation: org, name: t[:name], slug: t[:slug])
    end

    # ── Distribute memberships (primary + occasional secondary team) ────────
    org_users.each_with_index do |user, i|
      primary = teams[i % teams.length]
      ensure_membership(user: user, team: primary)

      # Every 3rd user gets a second membership for cross-team realism
      if (i % 3).zero?
        secondary = teams[(i / 3 + 2) % teams.length]
        ensure_membership(user: user, team: secondary) unless secondary == primary
      end
    end

    # ── Employee records ───────────────────────────────────────────────────
    # First 6 users become team leads (one per team, no manager).
    # The rest report to the lead of their primary team.
    team_leads = {}

    org_users.each_with_index do |user, i|
      fn    = SEED_FIRST_NAMES[i % SEED_FIRST_NAMES.length]
      ln    = SEED_LAST_NAMES[(i * 7) % SEED_LAST_NAMES.length]
      tidx  = i % teams.length
      title = i < teams.length ? "#{teams[i].name} Lead" : SEED_JOB_TITLES[i % SEED_JOB_TITLES.length]

      emp = ensure_employee(
        user:         user,
        organisation: org,
        display_name: "#{fn} #{ln}",
        job_title:    title,
        manager:      i < teams.length ? nil : team_leads[tidx],
      )
      team_leads[i] = emp if i < teams.length
    end

    # ── Projects (2 per team = 12 per org) ────────────────────────────────
    ORG_PROJECT_DEFS.each do |pdef|
      team = teams.find { |t| t.slug == pdef[:team_slug] }
      next unless team

      proj = ensure_project(
        organisation: org,
        name:         pdef[:name],
        slug:         "#{prefix}-#{pdef[:slug_suffix]}",
        team:         team,
        description:  pdef[:desc],
      )

      pdef[:lang_codes].each do |code|
        lang = langs[code]
        ProjectLanguage.find_or_create_by!(project_id: proj.id, language_id: lang.id) if lang
      end

      pdef[:tech_slugs].each do |slug|
        tech = techs[slug]
        ProjectTechnology.find_or_create_by!(project_id: proj.id, technology_id: tech.id) if tech
      end
    end
  end

  # ── Named per-org users (stable dev logins) ─────────────────────────────────
  alice  = ensure_user(email: "alice@acme.dev",          organisation: org_acme,    org_role: :admin)
  bob    = ensure_user(email: "bob@acme.dev",            organisation: org_acme,    org_role: :member)
  carol  = ensure_user(email: "carol@acme.dev",          organisation: org_acme,    org_role: :member)
  _dave  = ensure_user(email: "dave@acme.dev",           organisation: org_acme,    org_role: :member)
  grace  = ensure_user(email: "grace@globex.dev",        organisation: org_globex,  org_role: :admin)
  henry  = ensure_user(email: "henry@globex.dev",        organisation: org_globex,  org_role: :member)
  ensure_user(email: "solo@startup-labs.dev",            organisation: org_startup, org_role: :admin)

  # Named teams & memberships
  team_acme_eng     = Team.find_by!(organisation_id: org_acme.id,   slug: "engineering")
  team_acme_product = Team.find_by!(organisation_id: org_acme.id,   slug: "product")
  team_globex_core  = ensure_team(organisation: org_globex, name: "Core", slug: "core")

  ensure_membership(user: alice,  team: team_acme_eng)
  ensure_membership(user: bob,    team: team_acme_eng)
  ensure_membership(user: bob,    team: team_acme_product)
  ensure_membership(user: carol,  team: team_acme_product)
  ensure_membership(user: _dave,  team: team_acme_eng)
  ensure_membership(user: grace,  team: team_globex_core)
  ensure_membership(user: henry,  team: team_globex_core)

  # Named employee records (Carol and Henry intentionally have none)
  lead = ensure_employee(user: alice, organisation: org_acme,   display_name: "Alice Acme",   job_title: "Head of Engineering")
  ensure_employee(user: bob,   organisation: org_acme,   display_name: "Bob Builder",  job_title: "Senior Developer", manager: lead)
  ensure_employee(user: grace, organisation: org_globex, display_name: "Grace Globex", job_title: "CTO")

  # ── Named projects (kept for remote-resource / document fixtures below) ─────
  proj_phoenix  = ensure_project(organisation: org_acme, name: "Phoenix", slug: "phoenix",
                                  team: team_acme_eng, description: "Main customer app — team-scoped, stack-heavy.")
  proj_internal = ensure_project(organisation: org_acme, name: "Internal Tools", slug: "internal-tools",
                                  team: nil, description: "Org-wide utilities without an owning team.")
  proj_legacy   = ensure_project(organisation: org_globex, name: "Legacy Monolith", slug: "legacy-monolith",
                                  team: team_globex_core, description: "Older stack maintained by Core.")
  ensure_project(organisation: org_startup, name: "MVP", slug: "mvp",
                 team: nil, description: "Solo-founder project; org has no teams.")

  ProjectLanguage.find_or_create_by!(project_id: proj_phoenix.id,  language_id: langs["en"].id)
  ProjectLanguage.find_or_create_by!(project_id: proj_phoenix.id,  language_id: langs["typescript"].id)
  ProjectLanguage.find_or_create_by!(project_id: proj_internal.id, language_id: langs["ru"].id)

  ProjectTechnology.find_or_create_by!(project_id: proj_phoenix.id,  technology_id: techs["ruby-on-rails"].id)
  ProjectTechnology.find_or_create_by!(project_id: proj_phoenix.id,  technology_id: techs["hotwire"].id)
  ProjectTechnology.find_or_create_by!(project_id: proj_phoenix.id,  technology_id: techs["postgresql"].id)
  ProjectTechnology.find_or_create_by!(project_id: proj_internal.id, technology_id: techs["python"].id)

  # ── Remote resources ─────────────────────────────────────────────────────────
  rr = RemoteResource.find_or_initialize_by(project_id: proj_phoenix.id, name: "Payments API")
  rr.kind = "api_key"
  rr.url  = "https://api.example.com/v1"
  rr.credentials = JSON.generate("api_key" => "sk_dev_example_only", "region" => "eu-west-1") if Lockbox.master_key.present?
  rr.save!

  rr_bare = RemoteResource.find_or_initialize_by(project_id: proj_legacy.id, name: "On-prem broker")
  rr_bare.kind = "ssh"
  rr_bare.url  = ""
  rr_bare.save!

  # ── Project documents ─────────────────────────────────────────────────────────
  ProjectDocument.find_or_create_by!(project_id: proj_phoenix.id, title: "Architecture overview") do |d|
    d.url         = "https://docs.example.com/phoenix/architecture"
    d.external_id = "DOC-PHX-001"
    d.metadata    = { "kind" => "notion", "version" => 1 }
  end
  ProjectDocument.find_or_create_by!(project_id: proj_internal.id, title: "Runbook (no URL yet)") do |d|
    d.url      = ""
    d.metadata = {}
  end

  # ── Invitations ───────────────────────────────────────────────────────────────
  platform_user = User.find_by!(email: "platform@codenest.dev")

  ensure_pending_invitation(organisation: org_acme,    email: "pending-member@example.com",    invited_by: alice,         org_role: :member, expires_at: nil)
  ensure_pending_invitation(organisation: org_acme,    email: "pending-admin@example.com",     invited_by: alice,         org_role: :admin,  expires_at: 90.days.from_now)
  ensure_pending_invitation(organisation: org_globex,  email: "platform-invited@globex.dev",   invited_by: platform_user, org_role: :member, expires_at: 30.days.from_now)
  ensure_pending_invitation(organisation: org_startup, email: "open-invite@example.com",       invited_by: nil,           org_role: :member, expires_at: 14.days.from_now)
  ensure_accepted_invitation(organisation: org_globex, email: "former-candidate@globex.dev",   invited_by: grace,         org_role: :member, accepted_at: 2.months.ago)

  puts "Done. Dev logins (password for all: #{DEV_PASSWORD}):"
  puts "  Super admin:    platform@codenest.dev"
  puts "  Acme admin:     alice@acme.dev"
  puts "  Globex admin:   grace@globex.dev"
  puts "  Startup admin:  solo@startup-labs.dev"
  puts "  Bulk users:     dev001@acme.dev … dev050@acme.dev (same for globex.dev / startup-labs.dev)"
else
  Rails.logger.info { "db/seeds.rb: development fixtures skipped (#{Rails.env})." }
end
