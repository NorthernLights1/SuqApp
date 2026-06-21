# Open Tasks — Suq ERP

Last updated: 2026-06-21

---

## Wholesale support (NEW — retail/wholesale split)

shop_type chosen at onboarding, locked. `shopTypeProvider.isWholesale` is the gate.

- [x] Onboarding: business-type selection step (retail vs wholesale), saved to
  `shop_settings.shop_type`. Onboarding is now 5 steps.
- [x] Mandatory customer on every sale (wholesale) — new-sale `_submit` gate +
  "required" cue on the picker.
- [x] Custom units of measurement (both types) — inline "New unit" in product form.
  Online-only create; ponytail shortcut (offline add deferred).
- **Batch numbers + expiry (wholesale)** — LARGE, on branch `feat/batch-tracking`.
  Decisions (2026-06-21): auto-FEFO, expired = warn-but-allow, recall traceability
  IN (`sale_item_batches`), retail untouched.
  - [x] **Phase 1 — schema + local mirror.** Migration `028_product_batches.sql`
    (product_batches + sale_item_batches + rollup trigger keeping
    `inventory.quantity` = sum of batches + wholesale-only backfill). Drift
    `LocalProductBatches` (schema v12), delta-pull descriptor `_seedProductBatches`.
    Reads unchanged (rollup). **Migration NOT yet applied to live DB** — Temesgen
    to run it in the SQL editor (MCP exposed no tools; no CLI/connection available).
  - [x] **Phase 2 — batch-aware stock-IN (wholesale).** NO RPC needed: batches
    push as a replica table (idempotent upsert; the rollup trigger sums them,
    distinct UUIDs from different devices just add). Add Stock dialog gains a
    batch/lot field (wholesale); opening stock → batch; `addStockBatch`
    (local-first, recomputes local rollup); batch push in `SyncService` + added
    to the pending-work watcher. Correct Stock hidden for wholesale. Unit-tested
    (rollup sum, soonest-expiry, pending flag). **NOT verified end-to-end** — needs
    `028` applied + a wholesale shop on device.
  - [ ] **Phase 2.5 — wholesale Correct Stock + oversell-resolution** at the
    batch level (`conflicts_provider`); both currently hidden/retail-only because
    they write `inventory.quantity` directly, which the rollup would overwrite.
  - [ ] **Phase 3 — FEFO depletion on sale:** local + server FEFO (expiry asc,
    nulls last); warn on expired; write `sale_item_batches`; oversell via existing
    `stock_conflicts` (rollup feeds it).
  - [ ] **Phase 4 — surface expiry:** per-batch rows + expiry badges (wholesale
    inventory screen); optional near-expiry digest. Recall report (which customers
    got batch X) is a server-side query — small later task.
- [ ] **Refunds / returns** — schema (`refunds`/`refund_items`) already exists,
  unused. Must be offline-first. Restock-to-batch couples to batch tracking — do
  after it. (See "Blocked / Deferred" for the original deferral decision.)
- [ ] Extra customer fields (business_name / TIN / address) — deferred to ride
  with an invoice/printout feature (no display surface yet).
- A4 invoice / detailed printout — **dropped by Temesgen (2026-06-21)**.
  `printing`/`pdf` deps remain if revived.

---

## Offline-first — ✅ DONE (merged to main, PR #4, 2026-06-17)

Phases 1–3 + v2 engine (A–C) all complete. Two-device oversell conflict
testing still worth doing before wide rollout but is not blocking the pilot.

---

## Offline-first v2 — Phase D hardening (not blocking pilot)

Phases A–C complete. Remaining hardening items:
- [ ] Indexes on local Drift: `is_synced`, `updated_at`, `shop_id`, FKs.
- [ ] First-pull pagination + on-device retention policy (don't keep all history).
- [ ] Offline JWT refresh on reconnect (don't let an expired token silently fail sync).
- [ ] Operator sync-health debug view: last sync time, pending-push count, last error.
- [ ] SQLCipher for the local cache (now holds full shop PII) — still deferred past pilot.
- [ ] Audit SECURITY DEFINER functions for dynamic SQL / search_path (injection + priv-esc).

---

## Open bugs

- None currently open. (Bug 2/3 void-inventory-refresh, partial-settlement
  payment logs, voided-credit-drops-from-views, and Bug 7 offline-sale-in-report
  all confirmed fixed on device by Temesgen, 2026-06-21.)

---

## Unverified on-device

- [ ] **RLS Part 2:** run `supabase/rls_isolation_test.sql` Part 2 with two real
  accounts from different shops (cross-shop isolation; MCP bypasses RLS).

---

## Planned — Re-add lint tools (blocked on upstream)

- [ ] Re-add `custom_lint` + `riverpod_lint` once `custom_lint 0.9+` resolves the `analyzer ^9.0.0` vs `^8.0.0` conflict with `riverpod_lint 3.x`. Check pub.dev before attempting.

---

## Remaining offline gaps

- [ ] Product/category **edit** (`updateProduct`) still remote-only — create is offline-first but edit is not
- [ ] Widget tests for key screens (NewSaleScreen, SalesScreen)

---

## Deferred / Manual Steps

- [ ] Supabase Dashboard: enable Leaked Password Protection (Auth → Settings → Password Security — cannot do via SQL). Temesgen still deciding (2026-06-21).
- [x] Supabase: Magic Link email template includes `{{ .Token }}` — confirmed added & working (2026-06-21); staff OTP invite functional.

---

## Security — Deferred (decide before wide rollout)

- [ ] Encrypt the local on-device Drift/SQLite cache (SQLCipher). Supabase is
  encrypted in transit (TLS) and at rest (AWS AES-256), but the offline copy
  on each phone is currently plaintext — exposed if a device is lost/stolen.
  Deferred for the initial debug-APK pilot; do before wider distribution.
  (Raised session 16 while shipping the GitHub Actions APK build.)

---

## Tech Debt (tracked, not urgent)

- Hardcoded strings in screens violate l10n rule. l10n is scaffolded but NOT
  adopted: `AppLocalizations.delegate` is not registered in `app.dart` and no
  screen uses it. Adopt l10n app-wide as one dedicated task — do not localize a
  single feature in isolation (it'd be the lone consumer + risk a runtime null).
- No error boundaries — raw Supabase exceptions reach snackbars
- Permission cache TTL not implemented (role changes need app restart)
- `Decimal.parse()` without try-catch in models — can throw on malformed DB data
- Product/category edit still remote-only (tracked in "Remaining offline gaps" above)
- Expenses & customers still push as one bulk upsert — a single invalid row blocks
  that batch. Sales / adjustments / credit payments already push per-row
  (failure-isolated); give expenses & customers the same treatment.
- First sales pull caps at 2000 most-recent rows (unsettled credits unbounded);
  older sales come via delta/on-demand. Fine for the pilot; revisit pagination
  for very high-volume shops.
- Presentation providers call Supabase directly (read queries + the stock-conflict
  claim/resolve in `conflicts_provider`), bypassing the "modules behind interfaces"
  rule. This is the existing pattern across `customers_provider`, `reports_provider`,
  `settings_provider`, etc. — a repository-layer extraction is an app-wide cleanup,
  not a per-feature change. (CodeRabbit CR#6/#7.)

---

## EOD Cash Reconciliation — Deferred

- [ ] **End-of-day cash drawer reconciliation** (2026-06-18): float + cash sales −
  cash expenses = expected drawer vs. physical count → discrepancy report. Only
  useful if shop has staff handling cash (theft/error detection). Overkill if owner
  is the sole cashier. Revisit after pilot based on shop owner feedback.

---

## Data Backup & Recovery — Explore later

- [ ] **Device-level backup for offline data** (2026-06-18, session start): Users
  can restore their app data across uninstall via: (1) Supabase sync + login restore
  (already implemented, safest); (2) native device backup (iOS iCloud, Android backup
  service — minimal config); (3) manual export (CSV/JSON file). Explore which gives
  best UX offline, especially for unsynced local changes. Currently, uninstall loses
  local data if it hasn't synced to Supabase yet.

---

## Blocked / Deferred

- Chapa payments — out of scope v1
- Amharic l10n — translations not started
- Staff invite for existing Supabase users — Edge Function errors; users must use a fresh email
- Barcode scanning + product images — deferred post-v1
- Monetization / multi-branch pricing tiers — decision pending
- **Refunds / returns — DEFERRED (decided 2026-06-17)**. Void (same-day mistake,
  erases the sale) stays as-is. A refund (real sale, goods returned later — keeps
  the original sale, records cash out today, optionally restores stock, may be
  partial) is a distinct transaction type and deserves separate handling IF pilot
  shops actually process returns. Deferred for now. When built, must be
  offline-first from day one (do not repeat Bug 1).

---
*Related: [[INDEX]] · [[CURRENT_STATE]] · [[DECISIONS]] · [[BUGS_AND_FIXES]] · [[OFFLINE_QA_CHECKLIST]]*
