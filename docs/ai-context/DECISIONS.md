# Decisions — Suq ERP

---

## Decision: Offline-first — local DB is the read source; Supabase is sync only
Date: 2026-06-12 | Status: Active (branch `offline-first`, in progress)

The app must be fully usable with no internet; Supabase exists only for
multi-device sync. Every read screen reads the local Drift DB, and sync both
pushes local writes AND pulls server state down (was push-only).
- Pull cadence stays the existing 15-min backstop + reconnect/resume/cold-start
  triggers. NO Supabase Realtime (Temesgen: keep Supabase idle). Offline reads
  are "as of last sync" — a manager won't see another cashier's unsynced sales
  until reconnect (accepted).
- Conflict policy (two offline phones oversell same stock): both sales kept,
  stock may go negative; detect on sync → email the owner → in-app resolution
  screen explaining what happened (best-practice, edge case). [Phase 3]

---

## Decision: Staff invites use an email CODE, not a magic link
Date: 2026-06-09 | Status: Active

Magic-link/invite emails on mobile need a hosted landing page + platform deep links
(Android intent filters, iOS Universal Links). Chose an in-app email-code (OTP) flow that
works identically on web and mobile with zero hosting/deep-link setup. Owner pre-creates the
account (createUser, no email) so only invited emails can request a code. Requires the Supabase
Magic Link email template to include `{{ .Token }}`.

## Decision: Low-stock/overdue notifications are SCHEDULED, not per-sale
Date: 2026-06-09 | Status: Active

Per-sale low-stock alerts were spammy and needed a notification email set. Moved to a
server-side `pg_cron` sweep (9 AM & 9 PM EAT) calling the `cron-notifications` Edge Function,
which sends one combined digest (low stock + overdue) per shop. Runs app-closed. Recipient
defaults to the OWNER's auth email (+ optional second), which also removed the "no notification
email" failure. Cron→function auth via a Vault secret verified by a SECURITY DEFINER RPC (no
secret in code; service-role key isn't readable via MCP and edge env secrets can't be set via MCP).

## Decision: service_role keeps full table grants (server-only)
Date: 2026-06-09 | Status: Active

Restored `service_role` DML on all public tables after a blanket REVOKE broke all Edge Function
admin queries. service_role is used only server-side with the secret key (never exposed to
clients), so full grants do NOT weaken RLS, which governs anon/authenticated. Standard Supabase
config.

## Decision: Display names read cross-shop via SECURITY DEFINER helper (not denormalized)
Date: 2026-06-09 | Status: Active

To show staff names, widened `profiles` SELECT to shopmates via `private.shares_shop_with()`
rather than copying names onto `shop_users` (which is owner-write-only, so staff couldn't
populate it). Keeps `profiles` the single source of truth; no sync/staleness.

## Decision: Flutter + Supabase as core stack
Date: 2026-05-29 | Status: Active

Flutter for cross-platform mobile/web; Supabase for auth, DB, realtime, storage.
Reason: One codebase for Android + iOS + web; Postgres with RLS + auth out of the box.

---

## Decision: Drift for offline-first local DB
Date: 2026-05-29 | Status: Active

Use Drift (SQLite) as primary write target for sales. Sync to Supabase in background.
Reason: Type-safe, works on all Flutter platforms, good migration support.
Impact: `appDatabaseProvider` returns `AppDatabase?` — null on web. All callers must null-guard and fall back to Supabase-direct.

---

## Decision: Riverpod for state management
Date: 2026-05-29 | Status: Active — pinned to 2.x

`flutter_riverpod: ^2.6.1` + `riverpod_annotation: ^2.6.1`. `AsyncNotifier` for async writes, `FutureProvider` for reads. `StateProvider` / `StateNotifierProvider` used for simple mutable state.

Reason: Compile-time safety, clean async support, testable.

Migration to Riverpod 3.x is planned but not yet done. Do not bump the version in pubspec.yaml until the migration task is complete (see OPEN_TASKS.md). Riverpod 3.x removes `StateProvider`, `StateNotifierProvider`, and `valueOrNull` — all require code changes.

---

## Decision: Go Router for navigation
Date: 2026-05-29 | Status: Active — pinned to v14

`go_router: ^14.8.1` with `_AuthRefreshNotifier` listening to Supabase auth stream.
Router instantiated once as `late final` in `ConsumerStatefulWidget`. See BUGS_AND_FIXES.md for the router-in-build() bug.

Migration to go_router v17 is planned alongside the Riverpod 3.x migration.

---

## Decision: `decimal` package for all monetary values
Date: 2026-05-29 | Status: Active

All money + quantities use `Decimal`, never `double`.
Reason: Exact decimal arithmetic matching PostgreSQL `numeric`.
Rule: Never cast to double for math. Stored in SQLite via `TypeConverter<Decimal, String>`.

---

## Decision: SQL migrations run manually in Supabase dashboard
Date: 2026-05-29 | Status: Active

Migration files in `supabase/migrations/` are reference only; applied manually via SQL Editor.
Reason: No Supabase CLI set up.

---

## Decision: Separate GitHub repo for Suq
Date: 2026-05-29 | Status: Active

Repo: `NorthernLights1/SuqApp`. Push: `git push origin <branch>`.
Note: An older context file mentions a `suq/` subdirectory and `suq` remote — both are outdated. App lives at repo root.

---

## Decision: Inventory enforcement is unconditional (no mode dependency)
Date: 2026-06-02 | Status: Active

Context: Originally there was a `flexible`/`strict` mode toggle in Settings. `flexible` allowed sales even with insufficient/absent stock. The toggle caused confusion and was the root cause of a negative-stock bug.

Decision: Remove mode dependency from stock checks entirely.
- No stock record → always block
- Insufficient stock → always block
- Sufficient stock → always allow

Reason: "Flexible" mode led to a shadow-ledger problem — if the system allows sales without inventory discipline, shop owners just bypass the system. The Settings toggle still exists in the UI (`_InventoryModeTile`) but has no effect on enforcement — it should be removed in the next session.

The `shop_settings.inventory_mode` value is kept in DB for now but is no longer read by the sale flow.

---

## Decision: Inventory screen — merged products + stock list
Date: 2026-06-02 | Status: Active

Context: App had separate "Products" and "Stock" tabs, which was confusing — same data, two views.

Decision: Single unified list. Each row shows product + its current stock level inline.
- Tap → bottom sheet: Add Stock | Correct Stock | Edit Product Details
- "Not in inventory" shown in red for products with no `inventory` record

---

## Decision: Stock operations — Add vs Correct
Date: 2026-06-02 | Status: Active

Two operations:
1. **Add Stock** — additive (quantity received). No password. Writes `opening_stock` or `restock` to `inventory_adjustments`.
2. **Correct Stock** — absolute override (count was wrong). Requires owner's login password verified via `supabase.auth.signInWithPassword`. Writes `correction` to `inventory_adjustments`.

Reason: Separates normal operations (restock) from corrections (data fixes). Password gate prevents casual edits while preserving an escape hatch for genuine mistakes without driving owners to a paper shadow ledger.

---

## Decision: Credit settlement — partial payments allowed
Date: 2026-06-02 | Status: Active

Context: "Mark Settled" zeroed the full balance. No way to record partial payments.

Decision: Replaced with "Receive Payment" dialog. Pre-filled with full balance; owner can change amount.
- Amount ≥ balance → zero out (full settlement)
- Amount < balance → reduce by entered amount

Implementation: `CustomerFormNotifier.receivePayment(customerId, amount)` — fetches current balance, subtracts, updates. No separate "credit payments" table — balance is updated directly on `customers.credit_balance`.

Reason: Simple, matches how small shops track debt. If audit trail is needed later, a `credit_payments` table can be added.
