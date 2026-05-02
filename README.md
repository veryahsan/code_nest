# Code Nest

A SaaS platform for engineering teams &mdash; organisations, teams, projects,
technologies and Google-Docs-backed documentation, built on a Rails 8 monolith
with Hotwire + a JSON API surface.

This repository implements the architecture, data model, and stack defined in
the project's `architecture_standards.md`, `saas_system.md`, `onboard.md`,
and `stack.md`.

> Status: **Phase 0 &mdash; Bootstrap complete.** Authentication, organisations,
> teams, projects and integrations land in subsequent phases.

---

## Stack

| Layer | Technology |
|---|---|
| Runtime | Ruby 3.4.3 |
| Framework | Rails 8.0.5 (monolith-first) |
| Database | PostgreSQL 16 + JSONB |
| Cache / Pub-Sub / Jobs queue | Redis 7 |
| Background jobs | Sidekiq 7 |
| Realtime | ActionCable (Redis adapter) + Turbo Streams |
| Frontend | Hotwire (Turbo + Stimulus) + TailwindCSS 4 + Importmap |
| API | JSON:API serializers under `/api/v1`, JWT auth |
| Auth | Devise + OmniAuth (Google) + Pundit |
| Observability | Sentry, Lograge, Ahoy, Audited |
| Testing | RSpec, FactoryBot, Capybara, shoulda-matchers |
| CI | GitHub Actions (RSpec, Brakeman, bundler-audit, RuboCop, importmap audit) |
| Hosting | Render (Blueprint in `render.yaml`) |

---

## Architectural conventions

Per `architecture_standards.md`, the codebase follows a **monolith-first /
facade-architecture** layout:

```
app/
  controllers/   # thin; delegate to facades
  facades/       # orchestrate complete user flows (e.g. ProjectCreationFacade)
  services/      # single-purpose business logic (e.g. CreateProjectService)
  policies/      # Pundit RBAC policies (org / team / project / document)
  queries/       # reusable AR query objects
  decorators/    # presentation logic
  serializers/   # JSON:API serializers for /api/v1
  forms/         # form objects for complex input
  models/
  views/
  javascript/controllers/  # Stimulus controllers
```

Controllers call **facades**, never services directly. Services and facades
both inherit from base classes (`ApplicationService`, `ApplicationFacade`)
that expose a `Result` value object with `success?` / `failure?` semantics.

---

## Local development

### Prerequisites

* Ruby 3.4.3 (managed via rbenv / asdf)
* PostgreSQL 15+
* Redis 7+
* Node 20+ (only used during asset precompile)
* `libvips` (for ActiveStorage variants)

### One-time setup

```bash
git clone <repo-url> code_nest
cd code_nest
cp .env.example .env             # then fill in real values
bundle install
bin/rails db:prepare
```

### Run the app

```bash
bin/dev   # boots Puma + Tailwind watcher + Sidekiq via foreman (Procfile.dev)
```

Visit <http://localhost:3000>.

You can also run `foreman start`, but `bin/dev` is preferred locally because it
uses `Procfile.dev` and includes the Tailwind watcher.

### Run the test suite

```bash
bundle exec rspec
```

Coverage report (HTML in `coverage/`):

```bash
COVERAGE=true bundle exec rspec
```

### Quality gates

```bash
bin/rails quality:all          # rubocop + brakeman + bundler-audit
bundle exec rubocop --parallel
bundle exec brakeman --no-pager
bundle exec bundle-audit check --update
```

---

## Deployment to Render

The repository ships a `render.yaml` Blueprint that provisions:

1. **`code-nest`** &mdash; web service (free plan, Puma).
2. **`code-nest-worker`** &mdash; Sidekiq worker (Starter plan; see notes below).
3. **`code-nest-postgres`** &mdash; Postgres 16 (free).
4. **`code-nest-redis`** &mdash; Key Value / Redis (free).

### Steps

1. Push this repository to GitHub.
2. In Render, choose **New &rarr; Blueprint** and point it at the repo.
3. Provide the following environment variables when prompted (the rest are
   wired through the Blueprint):
   * `LOCKBOX_MASTER_KEY` &mdash; generate locally:
     `bundle exec ruby -rlockbox -e 'puts Lockbox.generate_key'`
   * `SIDEKIQ_USERNAME` / `SIDEKIQ_PASSWORD` &mdash; credentials for `/sidekiq`
   * `APP_HOSTS` &mdash; e.g. `code-nest.onrender.com`
   * `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` (when Phase 1 ships auth)
   * `SENTRY_DSN` (optional)
   * `CORS_ORIGINS` (comma-separated)
4. The first deploy runs `bin/render-build.sh` (bundle, asset precompile,
   `db:prepare`) and then `bin/render-start.sh`.

### Free-tier notes

* Render's free **Web Service** auto-suspends after 15 min of inactivity.
* Render does not currently offer a free **Background Worker** plan; the worker
  is set to `plan: starter` (~$7/mo). For a fully-free deployment, comment out
  the `code-nest-worker` block and temporarily set
  `config.active_job.queue_adapter = :async` in `config/environments/production.rb`.
  Switch back to Sidekiq before adding webhook integrations.

---

## Phase plan

| Phase | Scope |
|---|---|
| 0 (this commit) | Bootstrap, configs, deploy, CI |
| 1 | Auth (Devise + Google OAuth), Organisation, Team, Pundit baseline |
| 2 | Employees, manager hierarchy, invitations |
| 3 | Projects, Languages, Technologies, RemoteResource (encrypted), `ProjectCreationFacade` |
| 4 | Hotwire UX pass (Turbo Streams everywhere) |
| 5 | Google Docs integration, `DocumentationFacade`, webhooks |
| 6 | Notifications system (Turbo + email + Slack) |
| 7 | Observability rounding (Ahoy, Audited dashboards) |
| 8 | Hardening, rate limiting, dead-letter queues |

---

## License

Proprietary &mdash; portfolio project. All rights reserved.
