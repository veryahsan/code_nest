# Sign-up & Onboarding Flow

This document describes how a new person becomes an active Code Nest user and
how their account is connected to an organisation (the multi-tenant root).

The flow uses Devise's built-in `:confirmable` module for email verification and
a small amount of application logic to attach users to organisations after the
verification step.

---

## TL;DR

1. **Sign up** with just an email + password. No organisation is created at
   sign-up time anymore.
2. Devise sends a **confirmation email**. The account cannot sign in until the
   link is clicked.
3. When the user **clicks the confirmation link**:
   - If their email **domain already belongs to an existing organisation**
     (i.e. some other user with the same `@domain.com` is already attached to
     an org), the new user is **auto-joined to that organisation as a member**.
   - Otherwise, the user lands on the dashboard in an **onboarding state** with
     a single CTA: *Create organisation*.
4. Creating an organisation from the dashboard makes the creator that
   organisation's **admin** (`org_role: :admin`).

The sign-up form no longer asks for an organisation name; that step is deferred
until after the email is confirmed.

---

## Page-by-page walkthrough

### 1. `GET /register` — sign-up form

Plain Devise registration: `email`, `password`, `password_confirmation`. There
is no longer a custom `Users::RegistrationsController`; the default
`Devise::RegistrationsController` is used.

On submit:

- A `User` row is created with `organisation_id: nil` and `org_role: :member`
  (default).
- Devise sends `confirmation_instructions` to the supplied address.
- The user is redirected to `/` with the
  `devise.registrations.signed_up_but_unconfirmed` flash. They are **not**
  signed in (`allow_unconfirmed_access_for = 0.days`).

### 2. `GET /verify?confirmation_token=…` — email confirmation

Devise's standard `Devise::ConfirmationsController#show` flips
`confirmed_at`. Immediately after that, our `User#after_confirmation` hook
fires `Users::PostConfirmationFacade`:

```ruby
# app/models/user.rb
def after_confirmation
  super
  Users::PostConfirmationFacade.call(user: self)
end
```

The model is intentionally a one-line trigger — the policy lives in the
facade:

```ruby
# app/facades/users/post_confirmation_facade.rb
def call
  return success(@user) if skip_auto_attach?

  organisation = Organisations::FindByEmailDomainService.call(email: @user.email).value
  return success(@user) if organisation.nil?

  Users::AssignToOrganisationService.call(
    user: @user, organisation: organisation, role: :member,
  )
end
```

`Organisations::FindByEmailDomainService` is a pure read service: it looks
for the **oldest organisation** that already has a member whose email ends
in the same `@domain` part. The query is a single SQL `JOIN` with a `LIKE`
filter, scoped via `Organisation.sanitize_sql_like` to neutralise wildcard
characters.

After confirmation the user is redirected to `/login` (Devise default).

### 3. `GET /dashboard` — onboarding or workspace

`DashboardController#show` no longer redirects org-less users away. Instead:

- Super admins → redirect to `/admin` (unchanged).
- Users **with** an `organisation` → render the existing org workspace
  (teams, projects, pending invitations).
- Users **without** an organisation → render
  `app/views/dashboard/_onboarding.html.erb`, which is a single card with a
  *Create organisation* CTA.

### 4. `GET /organisations/new` — create-org form

A new `OrganisationsController` exposes only `new` and `create`. Both actions
require the user to be authenticated **and** to currently have no
organisation (otherwise they're redirected to `/dashboard`). Super admins
cannot create organisations either; they manage tenants from Active Admin.

### 5. `POST /organisations` — create organisation

The controller is a thin pass-through to `Organisations::CreationFacade`:

```ruby
# app/controllers/organisations_controller.rb
result = Organisations::CreationFacade.call(
  name: organisation_params[:name],
  owner: current_user,
)

if result.success?
  redirect_to dashboard_path, notice: "Welcome to #{result.value.name}…"
else
  @organisation = result.error
  render :new, status: :unprocessable_entity
end
```

The facade orchestrates three single-purpose services inside one
transaction:

1. `Organisations::GenerateUniqueSlugService` — derives a slug from the
   name, appending a numeric suffix when needed.
2. `Organisation#save` — persists the row.
3. `Users::AssignToOrganisationService` — links the owner as `:admin`
   (and refuses to do so for super admins).

Any failure inside the transaction is rolled back, and the facade returns
`failure(organisation_with_errors)` so the controller can re-render the
form at `:unprocessable_entity`.

---

## Domain auto-join — known limitations

The auto-join rule is intentionally simple: *"if any existing user with the
same email domain belongs to an organisation, you join that organisation."*
This is great for company tenants (`@acme.dev` people land in the Acme org
without manual invitations) but it has predictable edge-cases:

- **Free-mail providers (`gmail.com`, `outlook.com`, `yahoo.com`, …).** Two
  unrelated personal accounts that share a free-mail domain will collapse
  into the same tenant. If/when this becomes a real problem we should add a
  denylist (env-driven) that bypasses the auto-join — see
  `Organisation.matching_email_domain` for the natural extension point.
- **Sub-domains are not normalised.** `alice@eng.acme.dev` does **not**
  auto-join an org seeded by `bob@acme.dev`. This is conservative on
  purpose: we'd rather miss an auto-join than place someone in the wrong
  tenant.
- **Multiple tenants share a domain.** When several organisations have
  members with the same domain (typical for free-mail), the **oldest
  organisation wins** (`ORDER BY organisations.created_at LIMIT 1`). The
  tie-break is deterministic but somewhat arbitrary; tighten this up the
  moment we adopt a denylist.
- **Race between two new sign-ups for the same domain.** If two co-founders
  sign up for a brand-new domain and both verify before either creates an
  organisation, neither one is auto-joined; both will see the *Create
  organisation* CTA and could end up creating duplicate tenants. Document
  this explicitly to founders during onboarding emails until we add an
  invitation-based pre-claim flow.

---

## Roles after onboarding

| User action                | Resulting `org_role` |
| -------------------------- | -------------------- |
| Auto-joined via domain     | `:member`            |
| Created the organisation   | `:admin`             |
| Invited explicitly (later) | depends on invite    |

`super_admin` is a separate axis and is never auto-assigned by this flow.

---

## Files touched by the flow

The flow uses the project's services + facades architecture
(`app/services/application_service.rb`, `app/facades/application_facade.rb`).
Models stay pure data + integrity rules; controllers stay thin and call
**facades** (never services directly); facades orchestrate **services**.

### Services (single responsibility, return `Result`)

- `app/services/organisations/generate_unique_slug_service.rb`
- `app/services/organisations/find_by_email_domain_service.rb`
- `app/services/users/assign_to_organisation_service.rb`

### Facades (orchestrate services, manage transactions)

- `app/facades/organisations/creation_facade.rb` — tenant bootstrap.
- `app/facades/users/post_confirmation_facade.rb` — post-verification
  side-effects (today: domain auto-attach).

### Models / controllers / views

- `app/models/user.rb` — `:confirmable`, `after_confirmation` is a one-line
  trigger that calls `Users::PostConfirmationFacade`. Organisation is
  optional for non-super-admins.
- `app/models/organisation.rb` — pure data + integrity rules. Slug
  generation and email-domain lookups have moved to the services layer.
- `app/controllers/organisations_controller.rb` — calls
  `Organisations::CreationFacade`.
- `app/controllers/dashboard_controller.rb` — onboarding-aware.
- `app/views/dashboard/show.html.erb` &
  `app/views/dashboard/_onboarding.html.erb` — onboarding card.
- `app/views/organisations/new.html.erb` — create-org form.
- `app/views/devise/registrations/new.html.erb` — sign-up form (no org name).
- `config/routes.rb` — adds `resources :organisations, only: %i[new create]`,
  drops the `controllers: { registrations: … }` override.

### Test layout

- `spec/services/organisations/generate_unique_slug_service_spec.rb`
- `spec/services/organisations/find_by_email_domain_service_spec.rb`
- `spec/services/users/assign_to_organisation_service_spec.rb`
- `spec/facades/organisations/creation_facade_spec.rb`
- `spec/facades/users/post_confirmation_facade_spec.rb`
- `spec/requests/users/registrations_spec.rb` /
  `spec/requests/users/confirmations_spec.rb` /
  `spec/requests/organisations_spec.rb` — end-to-end coverage that
  the controllers + Devise hooks invoke the facades correctly.

---

## Manual smoke test

```bash
bin/dev
# In another shell:
bin/rails db:reset db:seed   # wipes + re-seeds dev fixtures
```

1. Open `http://localhost:3000/register`.
2. Sign up as `founder@acme.dev`. You should be redirected to `/` with the
   "confirmation link" flash.
3. Open the email in `letter_opener` (it pops up automatically) and click
   *Confirm my email*.
4. Sign in. You should land on `/dashboard` with the onboarding CTA.
5. Click *Create organisation* → name it "Acme" → submit. You're now Acme's
   admin.
6. Sign out. Sign up again as `colleague@acme.dev`, confirm, sign in. You
   should land on Acme's dashboard as a member, **without** going through
   the create-org flow.
