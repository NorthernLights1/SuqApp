# Suq — Mobile ERP for Small Shops

Suq is a mobile-first ERP for small shop owners, built with **Flutter** and **Supabase**.
It replaces paper ledgers with digital sales, inventory, customer credit, expenses, and
reporting — and it keeps working when the internet doesn't.

- **Package:** `com.temesgen.suq`
- **Repo:** [NorthernLights1/SuqApp](https://github.com/NorthernLights1/SuqApp)
- **Platforms:** Android, iOS, Web (offline features are native-only — see [Offline & Sync](#offline--sync))

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Dev Commands](#dev-commands)
- [Offline & Sync](#offline--sync)
- [Backend (Supabase)](#backend-supabase)
- [Conventions](#conventions)
- [Testing](#testing)
- [Contributing](#contributing)

---

## Features

| Area | What it does |
|------|--------------|
| **Sales** | Cart-based checkout, cash / bank / credit payments, per-line discounts, void with inventory reversal, color-coded sales list (cash / unsettled credit / settled credit / voided). |
| **Inventory** | Unified product + stock list, add stock (with optional price/threshold updates), opening stock, owner-gated absolute corrections, low-stock & expiry flags. |
| **Customers & Credit** | Customer records, credit sales, partial payments, per-bill settlement, outstanding-credit reconciliation. |
| **Expenses** | Categorized expense tracking with daily totals. |
| **Reports** | Sales, gross profit (cost-aware), outstanding credit, and expense breakdowns across day/week/month/year or a custom range, with optional product-category filtering. |
| **Staff & RBAC** | Invite staff by email code, role-based permissions (Owner / Manager / Cashier), suspend/reactivate (status, never hard-delete). |
| **Notifications** | Scheduled twice-daily (9 AM / 9 PM) low-stock and overdue-credit email digests. |
| **Settings** | Shop/branch config, notification recipients, manual sync. |

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| **Framework** | Flutter (Dart SDK `^3.12.0`) |
| **Backend** | Supabase — Postgres + Row Level Security, Auth (GoTrue), Edge Functions (Deno) |
| **Local DB** | [Drift](https://drift.simonbinder.eu/) (SQLite) — offline-first write queue + cache |
| **State** | [Riverpod](https://riverpod.dev) 3.x (`flutter_riverpod`, `riverpod_annotation`) |
| **Navigation** | `go_router` 17.x |
| **Money** | `decimal` — exact arithmetic matching Postgres `numeric` (never `double`) |
| **Connectivity** | `connectivity_plus` — drives auto-sync triggers |
| **Exports** | `pdf`, `printing`, `excel` |
| **i18n** | `flutter_localizations` + `intl`, ARB-based (`lib/l10n/app_en.arb`) |
| **Email** | [Resend](https://resend.com) via Edge Functions (custom domain) |

---

## Architecture

Clean-ish layering with a strict offline-first write path:

```
Presentation (screens, Riverpod providers)
        │  depends on interfaces only
        ▼
Domain (models, repository interfaces, services)
        │
        ▼
Data ── local (Drift)  +  remote (Supabase)
```

**Core principles**

1. **Offline-first writes.** Mutations are written to the local Drift DB first, then pushed
   to Supabase in the background. A `SyncService` retries anything that fails. See
   [Offline & Sync](#offline--sync).
2. **Modules behind interfaces.** Features never call Supabase / PDF / Excel libraries
   directly — everything goes through a repository or service interface, so the
   implementation is swappable and testable.
3. **Money is `Decimal`.** All monetary values and quantities use the `decimal` package,
   stored in SQLite via a `TypeConverter<Decimal, String>` and in Postgres as `numeric`.
4. **RBAC through `PermissionService`.** UI never checks `role == 'owner'` directly.
5. **No hardcoded strings or config.** User-facing text lives in `lib/l10n/app_en.arb`;
   configuration in `shop_settings` / `core/constants`.

---

## Project Structure

```
lib/
├── core/            # constants, services (sync, permissions, export, notifications), utils
├── data/
│   └── local/       # Drift database, schema, seed/sync-down service, providers
├── domain/          # models + interfaces (e.g. ISyncService)
├── features/        # auth, onboarding, dashboard, sales, inventory, customers,
│                    # expenses, reports, staff, supplies, settings
│   └── <feature>/
│       ├── data/         # remote (Supabase) access
│       ├── domain/       # repository + models
│       └── presentation/ # screens + Riverpod providers
├── l10n/            # app_en.arb + generated localizations
└── shared/          # router, theme, reusable widgets

supabase/migrations/ # SQL migrations (reference; applied manually — see Backend)
docs/ai-context/     # external memory for AI-assisted development
```

---

## Getting Started

### Prerequisites

- Flutter SDK (Dart `^3.12.0`)
- A Supabase project (URL + publishable/anon key)
- For Android device testing: Android SDK + command-line tools (`flutter doctor`)

### 1. Clone & install

```bash
git clone https://github.com/NorthernLights1/SuqApp.git
cd SuqApp
flutter pub get
```

### 2. Configure secrets

Secrets are **never** hardcoded. They live in `config/env.json`, which is gitignored.

```bash
cp config/env.json.example config/env.json
# then fill in your Supabase URL and anon (publishable) key
```

### 3. Apply the database schema

Migrations in `supabase/migrations/` are applied **manually** in the Supabase SQL Editor,
in order (`001_…` → `016_…`). See [Backend](#backend-supabase).

### 4. Generate code & run

```bash
dart run build_runner build       # Drift + Riverpod + JSON codegen
flutter gen-l10n                  # localizations

# IMPORTANT: always pass the credentials file
flutter run -d chrome --dart-define-from-file=config/env.json
```

---

## Dev Commands

```bash
flutter run -d chrome --dart-define-from-file=config/env.json   # run (web)
flutter run --dart-define-from-file=config/env.json             # run (device)
flutter build web --dart-define-from-file=config/env.json       # build

flutter analyze                    # must be clean before every commit
flutter test                       # run the test suite
flutter pub get                    # install/update deps
flutter gen-l10n                   # regenerate after editing app_en.arb
dart run build_runner build        # regenerate Drift / Riverpod / JSON code
```

> After changing any Drift table (`lib/data/local/app_database.dart`) you must re-run
> `build_runner` and bump `schemaVersion` with a migration step.

---

## Offline & Sync

Suq is built for erratic connectivity. On native platforms (Android/iOS), writes are
**local-first**: they go to a Drift queue immediately and never block on the network.

**Offline-capable today:** sales, expenses, inventory/stock adjustments, customer
create/edit. Each writes locally, then pushes to Supabase in the background; the
`SyncService` re-pushes anything that failed (idempotently).

**Auto-sync triggers** (all funnel into one idempotent `sync()`):

- connectivity restored (offline → online edge)
- app resumed / cold start
- right after sign-in
- a 15-minute foreground backstop
- a manual **Sync now** button in Settings

The `sync_logs` heartbeat is throttled so bursts of triggers don't spam the backend.

> **Web note:** the Drift local DB is unavailable on web (`appDatabaseProvider` returns
> `null`), so on web all reads/writes go straight to Supabase. The full offline experience
> is native-only.

> **Not yet offline:** product create/edit/deactivate and credit-balance settlement remain
> online operations.

---

## Backend (Supabase)

- **Database:** Postgres with Row Level Security on every table; helper functions live in a
  `private` schema with hardened `search_path`.
- **Migrations:** `supabase/migrations/*.sql` are reference files, applied **manually** via
  the Supabase SQL Editor (no CLI wired up). Run them in numeric order.
- **Edge Functions (Deno):**
  - `invite-staff` — owner-only; creates the invited account and emails a one-time code.
  - `cron-notifications` — twice-daily low-stock + overdue-credit digest; gated by a Vault
    secret verified through a `SECURITY DEFINER` RPC.
  - `dispatch-notifications` — on-demand notification sender.
- **Scheduling:** `pg_cron` + `pg_net` run `cron-notifications` at 06:00 and 18:00 UTC
  (9 AM / 9 PM EAT).
- **Email:** transactional email via Resend from a verified custom domain.
- **Auth keys:** uses the modern `sb_publishable_…` (client) / `sb_secret_…` (server) key
  system. `service_role` is server-only (Edge Functions) and never shipped to clients.

---

## Conventions

These are enforced in review:

1. No hardcoded values — config via `shop_settings` or `core/constants/`.
2. All modules behind interfaces — never call Supabase/PDF/Excel libs directly from features.
3. All monetary values use `decimal` — never `double`.
4. RBAC always through `PermissionService` — never check `role == 'owner'` in UI.
5. No hardcoded user-facing strings — use `lib/l10n/app_en.arb`.
6. Writes go local (Drift) first, then sync to Supabase in the background.
7. `flutter analyze` must be clean before every commit.

---

## Testing

```bash
flutter test
```

Coverage focuses on the data/domain layer — the Drift DB queries, offline-first repository
paths (offline write → pending queue, online read with pending union, web fallback), and
sale/stock enforcement logic. Repository tests use an in-memory Drift database
(`NativeDatabase.memory()`) with stub remotes.

---

## Contributing

- Branch off `main`: `git checkout -b feat/...` or `fix/...`
- Keep `flutter analyze` clean and tests passing.
- Open PRs against `main`.

The `docs/ai-context/` folder holds external project memory (current state, decisions,
bugs/fixes) used during AI-assisted development — start with `INDEX.md`.

---

*Suq — turning paper ledgers into a shop in your pocket.*
