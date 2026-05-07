# Single Sign-On (Google & GitHub)

This document explains how a person signs into Code Nest with **Google** or
**GitHub**, how their external account is linked to their `User` row, and
where the responsibilities live.

The flow re-uses Devise as the source of truth for sessions, layered on top
of OmniAuth. A separate `identities` table lets a single user link
**multiple** providers (and makes adding a third — e.g. Microsoft, SAML —
a no-schema-change change later).

For the password-based sign-up / confirmation / org-bootstrap flow, see
[`docs/onboarding_flow.md`](./onboarding_flow.md). SSO sign-in funnels into
the same post-confirmation facade so onboarding behaves identically across
both paths.

---

## TL;DR

1. User clicks **Continue with Google** (or GitHub) on `/login` or
   `/register`.
2. Browser is redirected to the provider, signs in, and is redirected
   back to `/users/auth/<provider>/callback`.
3. `Users::OmniauthCallbacksController` pulls the auth payload from
   `request.env["omniauth.auth"]` and hands it to
   `Users::OmniauthAuthenticationFacade`.
4. The facade resolves the payload to a `User` in this order:
   1. **Existing identity** for `(provider, uid)` → return its user.
   2. **Logged-in user** linking a new provider from settings → attach
      identity to `current_user`.
   3. **Local user** with the same email → attach identity to that user.
   4. **Brand-new visitor** → create a confirmed `User` + `Identity`,
      then run `Users::PostConfirmationFacade` so domain auto-attach &
      onboarding work the same as a confirmed sign-up.
5. Devise signs the user in. They land on `/dashboard` (or `/admin`
   for super admins, via `ApplicationController#after_sign_in_path_for`).

No password is ever asked of an SSO-only user. Forgot-password remains
available if they ever want to add a local password later.

---

## Architecture

```text
   +-----------+      POST /users/auth/google_oauth2
   |  Browser  | ───────────────────────────────────────────►
   +-----------+                                              ┐
        ▲                                                     │
        │  302 redirect to accounts.google.com                │
        │                                                     │ Rack middleware
        │  user authenticates, Google redirects back          │ (omniauth gem)
        ▼                                                     │
   GET /users/auth/google_oauth2/callback ◄──────────────────┘
        │
        ▼
   Users::OmniauthCallbacksController#google_oauth2
        │
        ▼
   Users::OmniauthAuthenticationFacade.call(auth:, current_user:)
        │
        ├── Users::FindByOmniauthIdentityService ─────────► sign_in
        ├── current_user present ─────────────────────────► Users::LinkOmniauthIdentityService, sign_in
        ├── User.find_by(email:) present ─────────────────► Users::LinkOmniauthIdentityService, sign_in
        └── neither ─────► Users::CreateFromOmniauthService ──┐
                                                              └─► Users::PostConfirmationFacade
                                                                      │
                                                                      └─► sign_in
```

This mirrors the project convention: **controllers call facades, and
facades orchestrate single-purpose services**. The model layer stays a
thin trigger surface.

---

## Page-by-page walkthrough

### 1. `/login` and `/register` — SSO buttons

`app/views/devise/shared/_omniauth_buttons.html.erb` iterates over
`Devise.omniauth_providers` and renders one `button_to` per provider.

Two non-obvious details that exist on purpose:

- The buttons are **POST**, not GET. The `omniauth-rails_csrf_protection`
  gem rejects GET requests to `/users/auth/<provider>` to prevent CSRF
  attacks. `button_to` produces a `<form method="post">` with the Rails
  CSRF token included.
- `data: { turbo: false }` is set on each button. OmniAuth's request
  phase responds with a 302 to a third-party origin
  (`accounts.google.com`, `github.com/login/oauth/authorize`); Turbo
  Drive cannot follow cross-origin redirects via `fetch`.

### 2. Provider request phase — `POST /users/auth/<provider>`

The `omniauth` gem is mounted as Rack middleware. It receives the POST,
generates the OAuth state nonce, and 302-redirects the browser to the
provider's authorisation URL with the right scopes:

| Provider        | Scope             | Why                                                                                      |
| --------------- | ----------------- | ---------------------------------------------------------------------------------------- |
| `google_oauth2` | `email,profile`   | Returns the user's verified primary email + display name.                                |
| `github`        | `user:email`      | Lets the strategy fetch the user's primary **verified** email even if it's not public.   |

For Google we also pass `prompt: "select_account"` so users on a shared
device aren't silently signed in as the wrong Google account.

### 3. Callback — `GET /users/auth/<provider>/callback`

OmniAuth populates `request.env["omniauth.auth"]` with an
`OmniAuth::AuthHash`. Devise routes the request to
`Users::OmniauthCallbacksController#<provider>` — which in our case just
delegates:

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
def google_oauth2 = handle_callback("Google")
def github       = handle_callback("GitHub")

private

def handle_callback(provider_label)
  result = Users::OmniauthAuthenticationFacade.call(
    auth: request.env["omniauth.auth"],
    current_user: current_user,
  )

  if result.success?
    sign_in_and_redirect(result.value, provider_label)
  else
    flash[:alert] = "#{provider_label} sign-in failed: #{result.error}"
    redirect_to new_user_session_path
  end
end
```

If the OmniAuth strategy itself fails (user cancels, invalid CSRF, bad
credentials, …) Devise routes to `#failure` instead, which re-displays
the login page with a friendly flash.

### 4. Resolution — `Users::OmniauthAuthenticationFacade`

The facade holds **all** identity policy and delegates each step to a
single-purpose service. The decision tree is:

```ruby
return failure(EMAIL_MISSING_ERROR) if email.blank?

existing = Users::FindByOmniauthIdentityService.call(provider:, uid:).value
return success(existing) if existing

return link_identity_to(@current_user) if @current_user

local = User.find_by(email: email)
return link_identity_to(local) if local

create_user_and_finish_onboarding
```

The four delegated objects are:

| Object | Responsibility |
| ------ | -------------- |
| `Users::FindByOmniauthIdentityService` | Read-only lookup by `(provider, uid)`. |
| `Users::LinkOmniauthIdentityService`   | Persist a new `Identity` row against an existing user. Used by both the `current_user` and email-match branches. |
| `Users::CreateFromOmniauthService`     | Create a confirmed `User` + first `Identity` in a single transaction. |
| `Users::PostConfirmationFacade`        | Run the same domain-auto-attach side-effects that fire after an email confirmation. |

`Users::CreateFromOmniauthService` runs in a single DB transaction:

1. Build `User.new(email:, password: Devise.friendly_token[0, 20])`.
2. `user.skip_confirmation!` so `confirmed_at` is set immediately —
   we trust the provider's verified email and don't want to send a
   redundant confirmation email.
3. Save the user, then create the `Identity` from the auth hash.

> **Why does the facade then call `Users::PostConfirmationFacade`
> explicitly?** Devise's `after_confirmation` callback fires from
> `confirm!`, but `skip_confirmation!` does **not** call it. The
> orchestrating facade therefore invokes the post-confirmation facade
> by hand so the SSO path behaves identically to the email-confirmation
> path documented in `docs/onboarding_flow.md`.

The four-branch resolution covers these real-world cases:

| Scenario                                                                                       | Branch                |
| ---------------------------------------------------------------------------------------------- | --------------------- |
| Returning SSO user                                                                             | Existing identity     |
| Logged-in local-password user clicks **Link GitHub** in settings                               | `current_user` branch |
| User with a local-password account uses Google for the first time (provider email matches)     | Email-match branch    |
| Brand-new visitor signs in with GitHub                                                         | Create-user branch    |

---

## Data model

```text
users                      identities
─────                      ──────────
id                         id
email           ◄─ FK ──   user_id
encrypted_password         provider     ("google_oauth2" | "github")
…                          uid          (provider's user id)
                           email        (snapshot of the provider email)
                           raw_info     (jsonb of extra.raw_info, for debugging)
                           timestamps
                           UNIQUE (provider, uid)
```

Migration: `db/migrate/20260507045500_create_identities.rb`.

`provider` is constrained at the model layer to
`Identity::PROVIDERS = %w[google_oauth2 github]`. A spec
(`spec/models/identity_spec.rb`) asserts that this list stays in sync
with `User.omniauth_providers` so the two never drift.

---

## Trust assumptions

The service trusts `auth.info.email` returned by both providers because:

- **Google**: `omniauth-google-oauth2` only ever returns emails that
  Google has already verified.
- **GitHub**: with the `user:email` scope, the strategy fetches the
  user's **primary verified** email via the GitHub API even when the
  public profile email is empty.

If you ever need stricter checks (e.g. require `auth.info.email_verified
== true` explicitly, or hit `https://api.github.com/user/emails` and
filter for `primary && verified`), do it inside
`Users::OmniauthAuthenticationFacade` — that's the single place that
decides whether to trust an email.

---

## What `password_required?` does

SSO-only users have no usable password — `Users::CreateFromOmniauthService`
generates a random 20-char token to satisfy `:validatable` on creation.
To stop Devise from
asking those users for a password later (for example when they edit
their profile), `User#password_required?` returns `false` once any
identity is linked:

```ruby
def password_required?
  return false if persisted? && identities.exists?

  super
end
```

This deliberately keeps the password requirement intact at *creation*
time so local-password sign-ups are still validated.

---

## Configuration & secrets

Provider apps must be created in each environment and the generated
client id / secret stored in env vars:

```bash
# .env (development)
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...
```

In production they should live in Rails credentials (or your host's
secret manager) and be exposed to the process via env vars. Missing
credentials don't crash the boot — the OAuth handshake will simply fail
with a flash, so a missing GitHub secret does not block Google sign-in.

### OAuth callback URLs to register with the provider

| Environment | Google                                                  | GitHub                                                  |
| ----------- | ------------------------------------------------------- | ------------------------------------------------------- |
| Development | `http://localhost:3000/users/auth/google_oauth2/callback` | `http://localhost:3000/users/auth/github/callback`       |
| Production  | `https://<your-host>/users/auth/google_oauth2/callback`   | `https://<your-host>/users/auth/github/callback`         |

GitHub's OAuth app expects `Authorization callback URL` to be **exact**
(no trailing slash, scheme matters).

---

## Files touched by the flow

### Migration & schema
- `db/migrate/20260507045500_create_identities.rb`

### Models
- `app/models/identity.rb` — `belongs_to :user`, validates `(provider, uid)` uniqueness, allow-list for `provider`.
- `app/models/user.rb` — adds `:omniauthable` with `omniauth_providers: %i[google_oauth2 github]`, `has_many :identities, dependent: :destroy`, and the `password_required?` override above.

### Facades
- `app/facades/users/omniauth_authentication_facade.rb` — orchestrates the four-branch decision tree and re-runs `Users::PostConfirmationFacade` for new SSO sign-ups.

### Services
- `app/services/users/find_by_omniauth_identity_service.rb` — read-only lookup by `(provider, uid)`.
- `app/services/users/link_omniauth_identity_service.rb` — persists an `Identity` row against an existing user.
- `app/services/users/create_from_omniauth_service.rb` — creates a confirmed user + first identity in one transaction.

### Controllers & routes
- `app/controllers/users/omniauth_callbacks_controller.rb` — thin HTTP shell over the facade.
- `config/routes.rb` — `devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }`.

### Configuration
- `config/initializers/devise.rb` — registers the two providers from `ENV`.
- `config/locales/en.yml` — `devise.omniauth.providers.<provider>` button labels.

### Views
- `app/views/devise/shared/_omniauth_buttons.html.erb` — the POST buttons.
- `app/views/devise/shared/_omniauth_icon.html.erb` — inline brand glyphs.
- `app/views/devise/sessions/new.html.erb` — renders the buttons under the password form.
- `app/views/devise/registrations/new.html.erb` — renders the buttons under the create-account form.

### Specs
- `spec/models/identity_spec.rb`
- `spec/services/users/find_by_omniauth_identity_service_spec.rb`
- `spec/services/users/link_omniauth_identity_service_spec.rb`
- `spec/services/users/create_from_omniauth_service_spec.rb`
- `spec/facades/users/omniauth_authentication_facade_spec.rb`
- `spec/requests/users/omniauth_callbacks_spec.rb`
- `spec/factories/identities.rb`
- `spec/support/omniauth.rb` — boots OmniAuth into `test_mode` and exposes `mock_omniauth(...)` / `mock_omniauth_failure(...)` helpers.

---

## Manual smoke test

Make sure you have credentials in `.env` first.

```bash
bin/rails db:reset db:seed   # wipes + re-seeds dev fixtures
bin/dev
```

1. Open `http://localhost:3000/login` and click **Continue with Google**.
   You should bounce to `accounts.google.com`, sign in, and land on
   `/dashboard`.
2. Sign out. Open `http://localhost:3000/register` and click
   **Continue with GitHub**. You should land on `/dashboard` as a brand
   new user (or, if your GitHub email is already in `users`, attached
   to that account).
3. Verify the row: `bin/rails runner 'pp User.last.identities'` —
   you should see one identity with the matching provider/uid.
4. Sign in again with the same provider. No duplicate user/identity is
   created (the existing-identity branch wins).
5. Cancel the OAuth flow at the provider's consent screen. You should
   be redirected to `/login` with an *"... was cancelled or failed"*
   flash.

---

## Adding a third provider later

Because identities are normalised, adding a provider is mechanical:

1. Add the strategy gem (e.g. `omniauth-microsoft_graph`).
2. Add the symbol to `User`'s `omniauth_providers: %i[…]`.
3. Add the provider name to `Identity::PROVIDERS`.
4. Add a `config.omniauth :provider, ENV[...], ...` block in
   `config/initializers/devise.rb`.
5. Add a `def <provider> = handle_callback("<Label>")` line to
   `Users::OmniauthCallbacksController`.
6. Add a button label key under `devise.omniauth.providers` in
   `config/locales/en.yml`.

No migration, no service changes — the resolution logic in
`Users::OmniauthAuthenticationFacade` is provider-agnostic and the
underlying services key off whatever `(provider, uid)` tuple OmniAuth
hands them.
