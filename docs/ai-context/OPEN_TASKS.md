# Open Tasks — Suq ERP

Last updated: 2026-06-12 (session 17)

---

## Offline-first (branch `offline-first`, in progress)

- [x] **Phase 1** — local Drift schema v5 (shop/branches/settings/payment
  methods/categories/units/profiles/credit_payments) + download/pull sync in
  SeedService + SyncScheduler push-then-pull on triggers + local-first
  shop/branch providers. (commits 54f5495, 77f4f46)
- [x] **Phase 2** — every read screen has an offline path: Today's Summary,
  Inventory, Customers, Expenses (+categories), Credits (list/per-customer/
  payment history), Reports (summary + drill-downs, recomputed locally),
  Settings. (commits 512bde8, 5e69eb9, 6509744)
  - Remaining polish: Sales tab offline list doesn't yet show customer/cashier
    names (Reports drill-down does).
- [x] **Phase 3** — oversell conflict system. Migration 021: `stock_conflicts`
  table + `detect_stock_conflict` trigger (records a conflict when inventory
  goes negative) + owner-only resolve RLS. Migration 022: product_id index.
  cron-notifications v3 adds a STOCK CONFLICTS digest section. App:
  conflicts_provider (stockConflictsProvider + ResolveConflictNotifier with a
  conditional-claim guard against concurrent resolves), StockConflictsScreen,
  owner-only dashboard banner (gated on owner-exclusive `settings.manage`),
  `/stock-conflicts` route. (commits baa2055, f9d4d09, aa92b11)
- [ ] **Verify offline end-to-end** on device: build APK from `offline-first`,
  confirm every screen loads offline, and force a two-device oversell conflict.
- [ ] Then merge `offline-first` -> `main`.
- [ ] Verify offline boot + every screen loads offline; keep 15-min pull.
- [x] Q1 — overdue email = all unpaid credits regardless of age (fn v6).

### Observed offline bugs (motivate the v2 refactor below)
- [ ] "Could not load payment methods" on sales screen offline (form lookup still
  reads Supabase, not local).
- [ ] "Could not load categories" on inventory add-item offline (same cause).
- [ ] Cannot settle credit offline (write is Supabase-direct).
- [ ] Credit detail shows no customer / cashier offline (join-derived fields are
  null in local path — need denormalization).
- [ ] All operations slower offline (local-fallback waits on network timeout
  instead of reading local-first).

---

## Offline-first v2 — absolute boundary + replica sync engine
See DECISIONS.md "Offline-first v2". Design approved 2026-06-13. Do in order.

**Code reality check (read 2026-06-14 — narrows scope; don't rebuild):**
- Outbox push ALREADY covers customers→sales→expenses→adjustments, FK-ordered,
  ALREADY idempotent (select-before-insert). `sync_service.dart`.
- Connectivity auto-trigger ALREADY exists (offline→online edge + 15-min + cold
  start). `sync_scheduler.dart`. (CURRENT_STATE tech-debt note was stale; fixed.)
- Observability infra partly exists: `sync_logs` heartbeat, `lastSyncedAt()`,
  `isSyncOverdue()`. Phase-D debug view just needs a screen.
- Confirmed broken: `getPaymentMethods` has NO local path (sales_repository.dart
  :64). `getSale`/`getSalesForBranch` are server-FIRST not local-first (:256-297)
  — same root cause as missing names (local rows lack customer/cashier/payment).
  `voidSale` (:248) + `createCustomer` (:80) are remote-first. Inline push in
  `createSale` (:217-233) duplicates SyncService — remove.
- Push is row-by-row w/ a SELECT per row (2N round trips) → batch into bulk upsert.
- Pull is full `seedAll` re-download → make delta.

**Phase A — Schema & boundary foundation (the non-negotiables)**
- [x] Migration `023_offline_sync_metadata.sql`: adds `updated_at` +
  `deleted_at` to all 16 replica tables, a server-set `set_updated_at()` trigger
  (fires on INSERT *and* UPDATE — offline-created rows get server receive-time so
  delta pull can't miss them), and a per-table `updated_at` index. Admin tables
  excluded. **APPLIED LIVE 2026-06-14 via Supabase MCP (apply_migration); verified
  all 16 tables have the columns/trigger/index.**
- [x] RLS audit done (read all CREATE-TABLE migrations): all 16 replica tables
  already have shop-scoped RLS via `is_shop_member` / `shop_id_from_branch`. No
  gaps found in code. System rows (`shop_id IS NULL` units/payment methods/expense
  cats) and same-shop profile names are intended shared data, not leaks.
  - [x] Part 1 (coverage) run live via MCP: zero replica tables without RLS. ✅
  - [ ] **MANUAL STEP (Temesgen): run Part 2 of `supabase/rls_isolation_test.sql`**
    — cross-shop isolation with two real accounts from different shops (needs a
    real authenticated session; MCP runs as postgres and bypasses RLS).
  - Security advisor (post-migration) flagged only PRE-EXISTING items, none from
    023: `detect_stock_conflict()` (trigger fn, SECURITY DEFINER) is RPC-exposed
    to anon/authenticated → revoke EXECUTE in Phase D DEFINER audit; leaked-password
    protection still off (already-tracked manual step); pg_net in public schema.
    My `set_updated_at()` is NOT security-definer and was not flagged.
- [x] UUID + idempotency confirmed already satisfied: writes use client-side
  `Uuid().v4()`; push is idempotent (select-before-insert). Converting to a single
  `upsert(onConflict:'id')` is folded into Phase B batching (removes the extra
  round trip) — no separate change needed now.
- [~] Local Drift schema migration: DEFERRED into Phase B/C by design — Phase A's
  server change does not alter the local schema. The local columns (store server
  `updated_at`, delta cursor) land when Phase B's pull *consumes* them, and the
  denormalized-name columns land in Phase C; both bump `schemaVersion` together
  with their `onUpgrade` steps so pilot devices migrate once, cleanly.

**Phase B — The sync engine (single Supabase boundary)**
- [ ] Define the sync registry: one descriptor per shop module (local+remote table,
  FK order, conflict policy, shop-scoped pull query).
- [ ] Outbox push: drain dirty rows in bulk upserts, FK order, mark synced on success,
  backoff on failure. Remove the inline fire-and-forget push from `SalesRepository`.
- [ ] Delta pull: `last_synced_at` cursor, pull `updated_at > cursor`, upsert by id,
  honor `deleted_at`. Replace per-trigger full `seedAll` (keep full pull for first
  login only, paginated).
- [ ] Auto-trigger sync on connectivity restored (+ keep app-start, 15-min, debounced
  post-write nudge). Run off the UI thread.
- [ ] License = narrow `get_my_license_status(shop_id)` RPC; never sync the licenses
  table.

**Phase C — Close the observed bugs via the new model**
- [ ] Point all form lookups (payment methods, categories, units) at local Drift.
- [ ] Move remaining writes to local-first + outbox: credit settlement, inventory
  (product create/edit, add/correct stock), expenses, customer edits.
- [ ] Denormalize customer + cashier names onto local sale rows so detail screens
  work offline.
- [ ] Switch any remaining "try Supabase → fallback" reads to local-first.

**Phase D — Sequenced-in hardening (not blocking)**
- [ ] Indexes on local Drift: `is_synced`, `updated_at`, `shop_id`, FKs.
- [ ] First-pull pagination + on-device retention policy (don't keep all history).
- [ ] Offline JWT refresh on reconnect (don't let an expired token silently fail sync).
- [ ] Operator sync-health debug view: last sync time, pending-push count, last error.
- [ ] SQLCipher for the local cache (now holds full shop PII) — still deferred past pilot.
- [ ] Audit SECURITY DEFINER functions for dynamic SQL / search_path (injection + priv-esc).

---

## Session 17 follow-ups

- [ ] **`security` branch — merge when ready.** Published, NOT merged. Trial
  (14 days) + 10-digit serial activation (per-key duration, no stacking, 7-day
  countdown banner) + remote per-shop block. Migrations 019/020 already applied
  live. Operator SQL for generating keys / blocking is in the session notes.
- [ ] **Verify on device:** partial-settlement shows all payment logs; voided
  credit drops out of all credit views (fixes are in but unverified on-device).
- [ ] **Local Drift cache encryption (SQLCipher)** — Supabase is encrypted in
  transit + at rest; on-device cache is plaintext. Defer past the pilot.
- [x] Email overdue/low-stock reminders to ALL configured `notification_email`
  rows — done (dispatch-notifications v5).

---

## Immediate / Next Session

- [x] Remove inventory mode toggle from Settings — done (session 7)
- [x] Watch `seedNotifierProvider` in `dashboard_screen.dart` — done (session 7)
- [x] Credits tab with per-bill settlement — done (session 11)
- [x] Sales list color-coding (cash / unsettled credit / settled credit / voided) — done (session 11)
- [x] SaleDetailScreen: transaction ref, customer info, settlement notes — done (session 11)
- [x] Post-sale stale lists bug (Sales tab + Credits tab not refreshing) — done (session 11)
- [x] Fix `ListTile` ink splash invisible warnings — done (session 12)
- [x] Fix `RenderFlex` overflow by 13px in cart item row — done (session 12)
- [x] Staff invite 403 + duplicate email — done (session 12, Edge Function v4)
- [ ] "Gaps" view — surface products sold as `untracked` to prompt owner to add them to inventory

---

## Notifications Phase (branch: `feat/notifications`)

- [x] Email notifications for low stock — done (session 13, dispatch-notifications Edge Function)
- [x] Email notifications for overdue credits — done (session 13, manual trigger in Settings)
- [x] Settings screen: notification config (email, overdue days) — done (session 13)
- [x] `RESEND_API_KEY` set as Supabase secret (verified present, 36 chars) — done
- [x] Resend custom domain `massivedynamic.dev` wired into dispatch-notifications `from` — done
- [ ] Telegram notifications — deferred (revisit later)

### Scheduled low-stock notifications — DONE (server-side cron, replaces per-sale)
- [x] Enabled `pg_cron` + `pg_net` (migration 016).
- [x] Edge Function `cron-notifications` (verify_jwt:false; gated by Vault `cron_secret`
  via `public.verify_cron_secret` RPC). Loops ALL shops; recipients = owner auth email
  (DEFAULT) + optional `notification_email` shop_setting; sends via Resend from
  `notifications@massivedynamic.dev`. Verified end-to-end (200, email sent).
  - v2: sends ONE combined daily digest per shop — LOW STOCK section
    (inventory JOIN products where quantity <= low_stock_threshold) + OVERDUE CREDITS
    section (sales is_credit, not settled, completed, older than `overdue_credit_days`
    setting, default 7). Each section appears only if non-empty; no email if both empty.
- [x] Two pg_cron jobs: `low-stock-am` (`0 6 * * *`) and `low-stock-pm` (`0 18 * * *`)
  UTC = 9 AM & 9 PM EAT. They call the function via `net.http_post`, reading the
  `cron_secret` from Vault at run time.
- [x] App: removed per-sale `_checkLowStock` from `sales_provider.dart`; relabeled the
  Settings email field to "Additional notification email (optional)" (owner always notified).
- Owner email as default recipient also removed the old "no notification email" 400.
- Note: the old per-sale path (`dispatch-notifications` low_stock) is now unused but
  still deployed; the manual "Send overdue reminders" button still uses it.

---

## Planned — Re-add lint tools (blocked on upstream)

- [ ] Re-add `custom_lint` + `riverpod_lint` once `custom_lint 0.9+` resolves the `analyzer ^9.0.0` vs `^8.0.0` conflict with `riverpod_lint 3.x`. Check pub.dev before attempting.

---

## Phase 5 — Remaining

- [ ] Inventory writes write-through to Drift (product create/edit, stock add/correct)
- [ ] Expense writes offline (record expense when offline)
- [ ] Auto-trigger `SyncService.sync()` on connectivity restored
- [ ] Widget tests for key screens (NewSaleScreen, SalesScreen)

---

## Deferred / Manual Steps

- [ ] Supabase Dashboard: enable Leaked Password Protection (Auth → Settings → Password Security — cannot do via SQL)
- [ ] Android Setup (one-time, do before device testing):
  1. Android Studio → Settings → Android SDK → SDK Tools → check **"Android SDK Command-line Tools (latest)"** → Apply
  2. `flutter doctor --android-licenses` (type y to each)
  3. `flutter doctor` — should show [√] Android toolchain
  4. Enable USB debugging on Android 10 phone → plug in → `flutter devices` → `flutter run --dart-define-from-file=config/env.json`
  5. Add `C:\Users\Hp\AppData\Local\Android\Sdk`, `C:\Users\Hp\.gradle`, `C:\Projects\SuqApp` to Windows Defender exclusions

---

## Security — Deferred (decide before wide rollout)

- [ ] Encrypt the local on-device Drift/SQLite cache (SQLCipher). Supabase is
  encrypted in transit (TLS) and at rest (AWS AES-256), but the offline copy
  on each phone is currently plaintext — exposed if a device is lost/stolen.
  Deferred for the initial debug-APK pilot; do before wider distribution.
  (Raised session 16 while shipping the GitHub Actions APK build.)

---

## Tech Debt (tracked, not urgent)

- Hardcoded strings in screens violate l10n rule (`app_en.arb` unused)
- No error boundaries — raw Supabase exceptions reach snackbars
- Permission cache TTL not implemented (role changes need app restart)
- `Decimal.parse()` without try-catch in models — can throw on malformed DB data
- Inventory writes (create/edit product, stock adjust) not yet write-through to Drift
- `FilteringTextInputFormatter` allows multiple decimal points — caught by `Decimal.tryParse` at validation but could be rejected earlier

---

## Blocked / Deferred

- Chapa payments — out of scope v1
- Amharic l10n — translations not started
- Staff invite for existing Supabase users — Edge Function errors; users must use a fresh email
- Barcode scanning + product images — deferred post-v1
- Monetization / multi-branch pricing tiers — decision pending
