# Vowd — agent & contributor guide

Conventions for this Rails app. Prefer matching existing patterns over introducing new stacks or style islands.

## Stack

- **Rails 7.1** (`config.load_defaults 7.1`), **Ruby** as configured in the repo.
- **Hotwire**: Turbo Drive + **Stimulus** only for client behavior. **Importmap** (`config/importmap.rb`) — no Webpack/Vite unless the project explicitly moves there.
- **Tailwind CSS v4** via `@import "tailwindcss"` and **`@theme`** tokens in `app/assets/tailwind/application.css`.
- **Minitest** for tests (`test/`), **fixtures** enabled in `test/test_helper.rb`.

## Wedding configuration (read this first)

- **`Wedding`** is an **ActiveRecord** model (`app/models/wedding.rb`). The string primary key is the site **slug** (subdomain). Site copy and settings live in typed columns plus JSON fields (`story`, `hero`, `faq`, etc.).
- **`TenantResolver`** + **`AppHost`** resolve the tenant from the request host: `{slug}.{APP_BASE_DOMAIN}` or a wedding’s `custom_domain`. Apex `APP_BASE_DOMAIN` is the platform (marketing, signup, login).
- **`WeddingConcern`** exposes request-scoped **`current_wedding`** (never a process-global memo). One **`AdminUser`** owns exactly one wedding (`admin_users.wedding_id`).
- Edit guest-facing content in admin **Website**; feature flags remain under admin **Settings**.

## Application structure

### Controller namespaces

- **`Platform::`** — marketing landing, signup, and login on the apex host.
- **`Public::`** — guest-facing wedding site (save the date, RSVP, root) on a wedding host.
- **`Admin::`** — staff UI on a wedding host; inherits **`Admin::BaseController`** (auth + ownership + `WeddingConcern`, **`layout "admin"`**).
- **`Dispo::`** — disposable camera experience under the `/dispo` scope on a wedding host.

Keep new features in the namespace that matches their audience and routing.

### Concerns and cross-cutting behavior

- Reuse **`WeddingConcern`** for anything that needs `current_wedding`.
- Resolve hosts via **`AppHost`** / **`TenantResolver`** — do not hardcode product domains.
- Follow existing auth patterns (platform signup/login + wedding-host admin session) instead of ad hoc checks in views.
- Admin actions must enforce `current_admin.wedding_id == current_wedding.id`.

### Models

- Generators are configured for **UUID primary keys** (`config/application.rb`). Models that need explicit UUID assignment use concerns such as **`UuidPrimaryKey`** where applicable.
- **Scope data by `wedding_id`** (and similar) so admin and public actions never leak across tenants.

### Services and jobs

- Put non-trivial domain logic in **`app/services/`** (e.g. `RsvpService`, `DisposableCamera::*`, `WeddingReminders::*`) with clear inputs/outputs and tests beside them in `test/services/`.
- Use **`ActiveJob`** (`app/jobs/`) for work that should run asynchronously (mailing, reminders, etc.), with **`config.active_job.queue_adapter`** as set per environment.

### `lib/`

- **`config.autoload_lib`** is enabled — place supporting Ruby under `lib/` when it is not Rails MVC code, and keep the autoload boundaries clear.

## Front-end

### No arbitrary JavaScript in views

- **Do not** embed `<script>` blocks, **`onclick`**, **`onchange`**, or other inline handlers in ERB.
- Implement behavior in **`app/javascript/controllers/*_controller.js`** (Stimulus), wired with **`data-controller`**, **`data-*-target`**, **`data-action`**, and **`data-*-value`** as needed.
- Prefer **small, reusable** controllers (e.g. bulk selection, auto-submitting a filter form) over page-specific one-offs when the pattern appears more than once.
- Controllers are **eager-loaded** from `app/javascript/controllers` via `app/javascript/controllers/index.js` — new files are picked up automatically by importmap.

### Turbo

- Use **`data-turbo-confirm`** (and Rails `data: { turbo_confirm: "..." }` helpers) for destructive or sensitive actions instead of legacy UJS `confirm` where Turbo handles the request.
- Layouts include Turbo and importmap tags consistently (`stylesheet_link_tag "tailwind", "data-turbo-track": "reload"`, `javascript_importmap_tags`).

## Tailwind and UI consistency

### Design tokens

- **Theme variables** live under **`@theme`** in `app/assets/tailwind/application.css` (colors, radii, shadows, fonts, `--color-bg-admin`, `--color-border`, etc.).
- Prefer **semantic tokens** and existing CSS variables over hard-coded hex values in new markup.

### Component classes

- Reuse established patterns in the same file: **`.btn`**, **`.btn-primary`**, **`.btn-secondary`**, **`.btn-danger`**, **`.btn-sm`**, **`.card`**, **`.form-group`**, **`.form-control`**, **`.alert-*`**, **`.badge-*`**, admin shell classes (**`.admin-shell`**, **`.admin-side-nav-*`**, etc.), and public layout utilities.
- Add new **shared** component styles to `application.css` (or a coherent layer) rather than scattering one-off arbitrary class strings across many templates when they repeat.

### Layouts

- **`layouts/admin.html.erb`** — admin chrome, flash, side nav.
- **`layouts/admin_auth.html.erb`** — sign-in.
- **`layouts/public.html.erb`** — marketing/guest site.
- **`layouts/dispo.html.erb`** — disposable camera (minimal).
- Use **`content_for`** / **`yield`** patterns consistent with existing layouts when introducing new sections.

## Views and helpers

- Extract repeated markup into **partials** (`_form.html.erb`, `_guest_fields.html.erb`, `public/shared/*`, etc.). Pass locals explicitly when it keeps partials clear.
- Put presentation helpers in **`ApplicationHelper`** or a focused helper module; **`admin_nav_link`** is an example of keeping nav logic out of templates.
- Keep ERB **thin**: iteration and structure only; heavy logic belongs in models, services, or helpers.

## Routes and HTTP verbs

- Prefer **RESTful** routes and the correct **HTTP verbs** (`delete` for destructive collection actions, etc.). Custom collection/member actions in `config/routes.rb` should stay easy to grep and name after the domain (`destroy_selected`, `destroy_all`, etc.).

## Testing

- **Controller** and **service** tests are first-class; mirror new endpoints and service APIs with tests.
- Use **`sign_in_admin`** from `test/test_helper.rb` for authenticated admin integration tests.
- Stub external I/O (e.g. storage clients) in tests rather than hitting real APIs.

## Security and configuration

- Layouts use **`csp_meta_tag`** — respect CSP when adding scripts or inline styles (prefer external Stimulus and CSS).
- Do not commit secrets; use **Rails credentials** or environment-specific config for keys (SMS, storage, etc.) per existing service objects.

## When adding a feature (checklist)

1. Correct **namespace** and **routes**.
2. **Scope** by wedding (or document why not).
3. **Tailwind**: tokens + existing **component classes**.
4. Any browser behavior → **Stimulus**, not inline JS.
5. Non-trivial logic → **service** (or model method if truly AR-bound).
6. Async side effects → **job**.
7. **Tests** for the happy path and at least one edge case.

---

*This file describes how Vowd is built today. If you change a global convention (e.g. JS bundler, CSS pipeline), update this document in the same change.*
