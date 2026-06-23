# Decisions — Suq ERP

---

## Decision: Per-lot stock correction = append-only adjustment ledger
Date: 2026-06-22 | Status: Active (`feat/batch-tracking`, migration `032`)

Correcting ONE lot's remaining (miscount / partial damage) is recorded as a
`batch_adjustments` row (delta + reason + created_by), NOT by mutating the
immutable `product_batches.quantity`. Temesgen chose "log an adjustment + reason"
over "just edit the quantity" — keeps a full audit trail and stays offline-safe
(append-only, idempotent, order-independent), matching the depletion model.
`remaining = received − Σ(sale_item_batches) − Σ(batch_adjustments)`. The rollup
and batch-conflict functions gain the adjustment term; everything that computes
remaining (local recompute, getProductBatches, sale FEFO availability) subtracts
it, so a corrected-down lot drops from stock AND from what's sellable.

## Decision: Sale↔batch traceability lives on Reports, not the inventory tap
Date: 2026-06-22 | Status: Active

Per-item inventory detail shows CURRENT state (what's on hand per lot). The
historical "which sale/customer drew from which lot, who sold it" is a recall/
audit need → a dedicated **recall report on the Reports screen** (server query
over `sale_item_batches`), not embedded under each batch. Keeps inventory about
"what do I have now"; reports about "what happened". (Recall report deferred.)

## Decision: web stays online-only (no WASM SQLite) — phone is the offline target
Date: 2026-06-22 | Status: Active

Drift/SQLite runs on phones, not in the browser (as configured), so web is
Supabase-direct (online-only) while the phone is offline-first. Same single
Supabase schema — only the read/write PATH differs. Every read must have a
web/Supabase-direct fallback (batch reads were missing one → fixed `8ff3b48`).
Enabling WASM SQLite on web (so browser testing matches the phone) was considered
and DEFERRED — extra setup (wasm+worker assets, COOP/COEP headers, "reset = clear
site data"); revisit if browser↔phone discrepancies become costly.

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
- **License = a question, not synced data** (B4 verified already-satisfied):
  the device reads only its OWN `shop_controls` row (3 cols) via an RLS-scoped
  direct select that fails open offline; `license_keys` is deny-all (no client
  policy); activation is the owner-only `activate_license` RPC. The tables are
  never in the sync registry and entitlement is never cached locally. A dedicated
  `get_my_license_status` RPC is optional polish, NOT required — RLS already gives
  the own-shop isolation, so building one would be churn + a prod migration for no
  security gain. Guardrail comment added in `seed_service.dart`.
- **Migrate-once**: the B1 local schema bump (v6→v7) that adds `LocalSyncState`
  also adds the denormalized-name columns Phase C needs (customer/cashier/payment
  on `LocalSales`), so pilot devices migrate one time across B+C.
- Triggering already satisfied by `SyncScheduler`; B just repoints `onPull` at the
  new delta pull. Optional debounced post-write nudge if needed.

## Decision: Retail vs Wholesale split via a locked `shop_type` setting
Date: 2026-06-21 | Status: Active

Suq targets both retail shops and (irregular) wholesalers/distributors — e.g. a
pharma distributor with no warehouse or barcode printer. Rather than fork the
app, one `shop_type` shop_setting (`'retail'` | `'wholesale'`) gates the
differences.

- **Chosen at onboarding (step 1, before naming the shop), LOCKED afterward.**
  Locking is intentional: switching mid-data has pricing/tier implications we
  haven't designed, and avoids weird half-migrated states. Revisit if a real
  need appears.
- **`shopTypeProvider`** (FutureProvider, local-cache fallback) +
  `AsyncValue<String>.isWholesale` extension is the single gate. Features wrap
  with `if (ref.watch(shopTypeProvider).isWholesale)`. No per-feature flags.
- **Wholesale gating so far:** customer mandatory on every sale (not just
  credit). Planned: batch/expiry tracking, refunds. Retail paths stay untouched
  so the simple shop keeps the simple flow.
- **Why not a column on `shops`?** `shop_settings` is the existing config
  mechanism, already synced to the local replica; a column would need a schema
  migration + model change for the same result. (Key rule #1: config via
  `shop_settings`.)

## Decision: Custom measurement units are create-online-only (for now)
Date: 2026-06-21 | Status: Active

`measurement_units` already allows shop-scoped rows (RLS) and is in the delta
pull, so reads/sync were free. Create writes straight to Supabase + optimistically
mirrors locally; the local units table has no `is_synced`/`shop_id` and no
SyncService push path. Units are reference data added rarely (usually online at
setup), so a full offline-first create path (schema bump + push descriptor) isn't
worth it yet. Add it if shops report needing to add units while disconnected.

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
Date: 2026-05-29 | Status: Active — on 3.x (migrated session 8)

`flutter_riverpod: ^3.3.1` + `riverpod_annotation: ^4.0.2`. `AsyncNotifier` for async writes, `FutureProvider` for reads. All `StateProvider`/`StateNotifierProvider` replaced with `Notifier` + `NotifierProvider`. All `.valueOrNull` replaced with `.asData?.value`.

Reason: Compile-time safety, clean async support, testable.

---

## Decision: Go Router for navigation
Date: 2026-05-29 | Status: Active — on v17 (migrated session 8)

`go_router: ^17.2.3` with `_AuthRefreshNotifier` listening to Supabase auth stream.
Router instantiated once as `late final` in `ConsumerStatefulWidget`. See BUGS_AND_FIXES.md for the router-in-build() bug.

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

## Decision: HR/payroll is a separate product; financial module is out of scope
Date: 2026-06-19 | Status: Active

Suq POS is a paper-ledger replacement for small shops — not a full ERP or financial module.

**HR/payroll**: Deferred as a future separate product (Suq HR). If ever built:
- `hr_integration` flag in `shop_settings` controls POS behaviour.
  - `false` (default) → POS manages staff directly via `shop_users` (standalone mode).
  - `true` → HR owns `shop_users` writes; POS reads staff as read-only (integrated mode).
- Clients who only need POS never flip the flag. One codebase handles both cases.
- Ethiopian labour law baseline: 7% employee + 11% employer pension (Proclamation 715/2011);
  income tax brackets 0–35% across 7 bands.

**Financial module** (supplier AP, formal invoicing, VAT 15%, bank reconciliation, true P&L,
budgets, multi-currency): explicitly out of scope. Different customer, different product.

---

## Decision: Credit settlement — partial payments allowed
Date: 2026-06-02 | Status: Active

Context: "Mark Settled" zeroed the full balance. No way to record partial payments.

Decision: Replaced with "Receive Payment" dialog. Pre-filled with full balance; owner can change amount.
- Amount ≥ balance → zero out (full settlement)
- Amount < balance → reduce by entered amount

Implementation: `CustomerFormNotifier.receivePayment(customerId, amount)` — fetches current balance, subtracts, updates directly on `customers.credit_balance`. `settleCreditSale` (credits tab per-bill flow) uses the `record_credit_payment` RPC which writes to the `credit_payments` table (migration 017/018, added session 15) for audit trail.

Reason: Simple, matches how small shops track debt.

---
*Related: [[INDEX]] · [[CURRENT_STATE]] · [[OPEN_TASKS]] · [[BUGS_AND_FIXES]] · [[FILE_MAP]]*
