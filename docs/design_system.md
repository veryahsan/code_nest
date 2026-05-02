# Code Nest Design System

This document explains how the frontend design system is structured, where every piece lives, and how to use it when building new views.

---

## Architecture Overview

The system has four layers that build on each other:

```
Layer 4  Stimulus controllers        (interactive behaviour)
Layer 3  ApplicationHelper DSL       (Ruby convenience methods)
Layer 2  Component partials          (reusable HTML fragments)
Layer 1  Design tokens               (single source of truth for color, type, shadow)
```

---

## Layer 1 — Design Tokens

**File:** `app/assets/tailwind/application.css`

All brand colors, shadows, and the font stack are defined in the Tailwind `@theme {}` block. Tailwind 4 generates a utility class for every token automatically.

### Brand color scale (violet)

| Token | Hex | Utility |
|---|---|---|
| brand-50 | #f5f3ff | `bg-brand-50` `text-brand-50` |
| brand-100 | #ede9fe | |
| brand-200–400 | … | |
| brand-500 | #8b5cf6 | default interactive |
| brand-600 | #7c3aed | primary button bg |
| brand-700 | #6d28d9 | hover |
| brand-900 | #4c1d95 | |
| brand-950 | #2e1065 | darkest |

### Semantic colors

Semantic states (success, warning, danger, info) delegate to Tailwind's built-in scales so every shade is always available:

| Semantic | Tailwind scale |
|---|---|
| success | emerald |
| warning | amber |
| danger | rose |
| info | sky |

### Semantic surface classes

These encode both light and dark mode in a single class name:

| Class | Light | Dark |
|---|---|---|
| `bg-surface` | zinc-50 (off-white) | zinc-950 |
| `bg-surface-raised` | white | zinc-900 |
| `border-surface` | zinc-200 | zinc-800 |
| `text-base-color` | zinc-900 | zinc-50 |
| `text-muted-color` | zinc-500 | zinc-400 |

Use these on layout wrappers so you never need to repeat `dark:` modifiers inline.

### Dark mode

Dark mode is toggled by adding the `.dark` class to `<html>`. The `theme_controller.js` Stimulus controller manages this. User preference is stored in `localStorage` under the key `cn-theme`.

To avoid a flash of the wrong theme before JavaScript loads, the layout includes an inline script that reads `localStorage` and applies `.dark` synchronously before the page renders.

---

## Layer 2 — Component Partials

**Directory:** `app/views/components/`

Every reusable UI element is a Rails partial. Call them with `render "components/name", local: value`.

### Button (`_btn.html.erb`)

```erb
<%= render "components/btn",
      label:   "Save project",
      variant: :primary,
      size:    :md %>
```

**Variants:** `:primary` `:secondary` `:danger` `:ghost` `:link`
**Sizes:** `:sm` `:md` `:lg`
**Extra options:** `disabled:`, `loading:`, `href:`, `type:`, `data:`, `icon_only:`, `extra_class:`

When `href:` is provided, a `<a>` tag is rendered instead of `<button>`.
When `loading: true`, a spinner replaces the label and the button is disabled.

---

### Badge (`_badge.html.erb`)

```erb
<%= render "components/badge", label: "Active", variant: :success %>
<%= render "components/badge", label: "Active", variant: :success, dot: true %>
```

**Variants:** `:neutral` `:brand` `:success` `:warning` `:danger` `:info`

Or use the helper: `<%= badge_tag "Active", variant: :success %>`

---

### Alert (`_alert.html.erb`)

```erb
<%= render "components/alert",
      message:     "Project deleted.",
      variant:     :danger,
      title:       "Deletion failed",
      dismissible: true %>
```

**Variants:** `:success` `:warning` `:danger` `:info` `:neutral`
**Options:** `title:`, `dismissible:`, `icon:` (default true)

Or use the helper: `<%= alert_tag "Saved!", variant: :success %>`

---

### Card (`_card.html.erb`)

```erb
<%= render "components/card", title: "Team members" do %>
  content here
<% end %>
```

**Options:** `title:`, `description:`, `shadow:`, `padded:` (default true)

For full manual control use the section classes directly:

```html
<div class="card">
  <div class="card-header"> title </div>
  <div class="card-body">   body  </div>
  <div class="card-footer"> actions </div>
</div>
```

---

### Spinner (`_spinner.html.erb`)

```erb
<%= render "components/spinner", size: :md %>
<%= spinner_tag size: :lg, color: "text-brand-600" %>
```

**Sizes:** `:sm` `:md` `:lg`
**Options:** `label:` (accessible title), `color:` (Tailwind text-* class)

---

### Empty State (`_empty_state.html.erb`)

```erb
<%= render "components/empty_state",
      icon:         :inbox,
      title:        "No projects yet",
      description:  "Create your first project.",
      action_label: "New project",
      action_href:  new_project_path %>
```

**Icons:** `:inbox` `:search` `:folder` `:document`

---

### Page Header (`_page_header.html.erb`)

```erb
<%= render "components/page_header",
      title:       "Projects",
      description: "All projects for the Acme Engineering team.",
      breadcrumbs: [
        { label: "Dashboard", href: root_path },
        { label: "Projects" }
      ] %>
```

To add right-side action buttons:

```erb
<% content_for :page_actions do %>
  <%= render "components/btn", label: "New project", variant: :primary %>
<% end %>

<%= render "components/page_header", title: "Projects" %>
```

---

### Modal (`_modal.html.erb`)

```erb
<%# Define the modal (place near bottom of page) %>
<%= render "components/modal", id: "confirm-delete", title: "Delete project" do %>
  <p>Are you sure?</p>
  <div class="mt-6 flex justify-end gap-2">
    <button class="btn-base btn-secondary btn-md" data-action="click->modal#close">Cancel</button>
    <%= render "components/btn", label: "Delete", variant: :danger %>
  </div>
<% end %>

<%# Trigger the modal from a button %>
<button data-action="click->modal#open"
        data-modal-outlet="#confirm-delete"
        class="btn-base btn-danger btn-sm">
  Delete
</button>
```

**Options:** `id:` (required for targeting), `title:`, `size:` (`:sm` `:md` `:lg` `:xl`), `hide_close:`

The modal:
- Closes on Escape key
- Closes on backdrop click
- Traps keyboard focus inside
- Blocks page scroll while open

---

### Form Group (`_form_group.html.erb`)

```erb
<%= render "components/form_group",
      label:    "Email address",
      for_id:   "user_email",
      required: true,
      hint:     "We'll never share your email.",
      error:    @user.errors[:email].first do %>
  <%= f.email_field :email,
        id: "user_email",
        class: cn("input", @user.errors[:email].any? && "input-error") %>
<% end %>
```

**Options:** `label:`, `for_id:`, `hint:`, `error:`, `required:`

---

## Layer 3 — ApplicationHelper DSL

**File:** `app/helpers/application_helper.rb`

| Helper | Purpose |
|---|---|
| `cn(*classes)` | Merge class strings, filter nil/false (like JS `clsx`) |
| `badge_tag(label, **opts)` | Inline badge without explicit `render` |
| `alert_tag(message, **opts)` | Inline alert |
| `spinner_tag(**opts)` | Inline spinner |
| `input_classes(has_error)` | Returns `"input"` or `"input input-error"` |
| `page_title(title)` | Sets `content_for(:title)` and returns the title string |
| `turbo_frame_wrap(id)` | Wraps content in a Turbo Frame tag |
| `form_group_tag(label:, ...)` | Layout partial wrapper for form fields |

### `cn()` example

```ruby
<input class="<%= cn("input", @user.errors[:email].any? && "input-error") %>">
```

---

## Layer 4 — Stimulus Controllers

**Directory:** `app/javascript/controllers/`

All controllers are auto-loaded via `stimulus-loading` eager loading. You do not need to import or register them manually.

| Controller | Purpose | Key actions |
|---|---|---|
| `theme` | Dark / light toggle, reads / writes `localStorage` | `toggle` `setDark` `setLight` |
| `flash` | Auto-dismiss flash messages after a delay | `dismiss` |
| `modal` | Open / close modal with backdrop + focus trap + Esc | `open` `close` `closeOnBackdrop` |
| `dropdown` | Toggle a floating menu, close on outside click / Esc | `toggle` `open` `close` |
| `loader` | Swap button text with spinner during async operations | `start` `stop` |
| `clipboard` | Copy text to clipboard with visual feedback | `copy` |
| `dismissible` | Remove any element from the DOM with a fade | `dismiss` |

### Dark mode toggle

The toggle button in the navbar wires directly to the `theme` controller on `<html>`:

```html
<button data-action="click->theme#toggle">Toggle</button>
```

### Loading button

```html
<button class="btn-base btn-primary btn-md"
        data-controller="loader"
        data-loader-label-value="Saving…"
        data-action="click->loader#start">
  Save
</button>
```

### Dismissible alert

```html
<div data-controller="dismissible" data-dismissible-delay-value="5000">
  <p>Auto-dismisses after 5 seconds.</p>
  <button data-action="dismissible#dismiss">×</button>
</div>
```

---

## Cheat Sheet: Using the System in a New View

```erb
<%# 1. Page header %>
<%= render "components/page_header",
      title: "Projects",
      description: "Manage your team's projects." %>

<%# 2. Content card %>
<%= render "components/card", title: "All projects" do %>

  <%# 3. Empty state when list is empty %>
  <% if @projects.empty? %>
    <%= render "components/empty_state",
          icon:         :folder,
          title:        "No projects yet",
          action_label: "New project",
          action_href:  new_project_path %>
  <% else %>
    <%# list of projects... %>
  <% end %>

<% end %>

<%# 4. Alert for flash-style inline messages %>
<%= alert_tag "Project saved.", variant: :success %>

<%# 5. Form with validation %>
<%= form_with model: @project do |f| %>
  <%= render "components/form_group",
        label: "Project name",
        required: true,
        error: @project.errors[:name].first do %>
    <%= f.text_field :name,
          class: input_classes(@project.errors[:name].any?) %>
  <% end %>
  <%= f.submit "Save",
        class: "btn-base btn-primary btn-md",
        data: { controller: "loader",
                loader_label_value: "Saving…",
                action: "click->loader#start" } %>
<% end %>

<%# 6. Confirmation modal %>
<%= render "components/modal", id: "delete-confirm", title: "Delete project" do %>
  <p class="text-sm text-muted-color">This cannot be undone.</p>
  <div class="mt-6 flex justify-end gap-2">
    <button class="btn-base btn-secondary btn-md" data-action="click->modal#close">Cancel</button>
    <%= render "components/btn", label: "Delete", variant: :danger %>
  </div>
<% end %>
```

---

## Live Showcase

Open `http://localhost:3000` while running `bin/dev` to see every component rendered with all variants, states, and interactive demos.
