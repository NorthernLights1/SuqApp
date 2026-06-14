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

## Decision: Offline-first v2 — absolute boundary + device-as-replica sync engine
Date: 2026-06-13 | Status: Active (supersedes the partial migration; branch `offline-first`)

**Why now:** the partial migration left bugs — payment-method and category dropdowns
fail offline, credit settlement can't run offline, credit detail shows no
customer/cashier offline, and *everything* is slower offline. Root cause: list-reads
were moved local, but form lookups, several writes, and join-derived fields still hit
Supabase, and the read pattern is "try Supabase → timeout → fall back to local"
(fallback, not local-first), so the network sits on the critical path.

**Mental model — the device is a replica of ONE shop, not a copy of the database.**
Sync means "give me my shop's rows." Anything that isn't a shop's row data is, by
definition, out of scope. This makes the customer/admin split fall out for free.

**Core principles:**
1. **Absolute boundary.** Feature/transaction code NEVER touches Supabase — it only
   reads/writes local Drift. A single sync service is the *only* thing that talks to
   Supabase. (Removes the inline fire-and-forget push from `SalesRepository`.)
2. **Local-first, not local-fallback.** Reads return from local immediately; the
   network is never on a user-visible path. Online and offline become equal speed.
3. **One sync registry.** Syncable shop modules are declared as a small list of
   descriptors (local+remote table, FK order, conflict policy, shop-scoped pull
   query). Adding a module = add one descriptor. ~12 stable entries.

**Customer vs admin split — no per-table tagging, two layers instead:**
- **RLS is the boundary.** The anon key ships inside the APK and is public; RLS is the
  *only* wall between a user and other shops' data. Shop users physically cannot
  `SELECT` operator/admin tables (licenses, key generation, block list) — so admin
  data can never enter the replica even if the registry were wrong.
- **License is a question, not synced data.** The device never pulls the licenses
  table; it calls a narrow `get_my_license_status(shop_id)` RPC returning a single
  derived status (active/blocked/expires_at). Entitlement stays server-authoritative.

**Sync engine design:**
- **Push** via an outbox: local writes mark rows dirty (`is_synced=false`); the service
  drains them in **bulk upserts** (never row-by-row), in FK-dependency order,
  **idempotent by UUID** so a re-push after a crash can't duplicate.
- **Pull** is **delta, not full re-download**: a `last_synced_at` cursor pulls only
  rows where `updated_at > cursor`, upsert by id. Requires `updated_at` + `deleted_at`
  (soft delete) on every shop table.
- **Conflict policy** per table: last-write-wins for transactional/config rows;
  inventory quantity keeps the Phase 3 negative-stock detection (accumulator, not a
  value). All conflict logic lives inside the sync service.
- **Triggers:** app start, **connectivity restored** (currently missing), 15-min timer,
  debounced nudge after each local write. All non-blocking, off the UI thread.

**Three non-negotiables (painful to retrofit — get right at the migration):**
1. **`updated_at` is set server-side (`now()` trigger), never trusted from the device.**
   Delta sync + LWW both depend on it; a wrong device clock would corrupt ordering.
2. **RLS airtight and tested** (try to read another shop's rows with a normal token),
   because the anon key is public and the replica makes the client read broadly.
3. **Idempotent upsert-by-UUID push**; UUIDs generated client-side so rows are valid
   before sync.

**Sequenced in, not blocking:** batch push/pull, local-DB indexes on
`is_synced/updated_at/shop_id/FKs`, paginated first pull + on-device retention
(don't keep all history forever), local Drift schema migration for existing pilot
devices, offline JWT refresh on reconnect, operator sync-health debug view, and
SQLCipher for the now-larger plaintext PII replica (still deferred past pilot).

**Explicitly NOT doing:** Supabase Realtime (polling is cheaper for single-device
shops; revisit for multi-device-same-shop).

---

## Decision: Offline-first v2 Phase B — delta pull, batched push, sync registry
Date: 2026-06-14 | Status: Planned (branch `offline-first`)

Builds the single-boundary sync engine on the Phase A metadata (`updated_at` /
`deleted_at`, applied live in 023). Grounded in the current code:
`SeedService.seedAll` (full re-download every trigger), `SyncService` (row-by-row
push of customers/sales/expenses/adjustments), `SyncScheduler` (already triggers
on reconnect/timer/cold-start), `SalesRepository.createSale` (has an inline
fire-and-forget push to remove).

- **Per-table cursor**, not global. New local Drift table `LocalSyncState
  (tableKey PK, lastPulledAt)` (`tableKey`, not `tableName` — Drift reserves
  `tableName`). Each table advances independently so one table's failed pull
  doesn't stall the rest. (Decided — global cursor is too coarse.) The cursor is
  **single-shop by design**: the device replicates exactly one shop per session,
  so no `shopId` is keyed in. If multi-shop-per-device ever lands, the key becomes
  `(shopId, tableKey)` and the local DB is cleared on shop switch.
- **Delta pull** replaces full `seedAll` on every trigger: per table, fetch
  `where updated_at > cursor order by updated_at`, upsert live rows, DELETE rows
  whose `deleted_at` is set, then advance the cursor to the max `updated_at` seen.
  First pull (null cursor) = full, paginated download; keep the existing 366-day /
  2000-row windowing for sales/expenses history depth.
- **Sync registry**: one descriptor per replica module (remote table + columns,
  local upsert, pending-skip rule, conflict policy). The pull loop is registry-
  driven instead of 13 hand-written `_seedX` methods. Adding a module = one entry.
- **Batched, idempotent push**: convert `SyncService` from select-before-insert,
  row-by-row to a single bulk `upsert(onConflict:'id')` per table, in FK order
  (customers → sales → sale_items → …). Removes the extra round trip and is
  idempotent by UUID. **Remove the inline push from `SalesRepository.createSale`**
  — the local write only marks `isSynced=false`; `SyncService` is the sole pusher.
- **Conflict policy**: LWW (≈ last-push-wins) for config/customer/product edits;
  the pull already skips rows with a pending local version (push owns them). Stock
  oversell keeps the Phase 3 negative-stock detection. All conflict logic stays in
  the sync layer.
- **License = a question, not synced data**: device calls a narrow
  `get_my_license_status(shop_id)` RPC for active/blocked/expires; `license_keys` /
  `shop_controls` are never in the registry (already excluded in Phase A).
- **Migrate-once**: the B1 local schema bump (v6→v7) that adds `LocalSyncState`
  also adds the denormalized-name columns Phase C needs (customer/cashier/payment
  on `LocalSales`), so pilot devices migrate one time across B+C.
- Triggering already satisfied by `SyncScheduler`; B just repoints `onPull` at the
  new delta pull. Optional debounced post-write nudge if needed.

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
