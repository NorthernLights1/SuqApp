# Open Tasks — Suq ERP

Last updated: 2026-06-22

---

## 2026-06-22 session — wholesale batch follow-ups (committed, UNPUSHED)

Branch `feat/batch-tracking`. Migrations `031`/`032` applied live via MCP. 154 tests.
- [x] #1 batch/lot number REQUIRED at first stock-in (wholesale) — `384c620`.
- [x] #2 per-lot **Batch details** page + **added-by** (`031`, Drift v15) — `6d684ee`.
- [x] #3 per-lot **correction** (`batch_adjustments` ledger `032`, Drift v16) +
  **add-batch** action on the details page — `905ad18`. Chosen model: append-only
  adjustment + reason (audit trail), offline-safe.
- [x] BLOCK-MERGE review fixes — `1365841` (v14 migration crash guard; atomic
  createSale; reject no-lot wholesale sale; rollup clears stale expiry).
- [x] Web batch-details fallback (`8ff3b48`) — Chrome has no Drift; batch reads now
  fall back to Supabase like every other read.
- [x] **#4 Reports segregation** (Sales / Inventory / Expenses / Revenue) —
  DONE 2026-06-22 `c17c0d1`. Card hub → 4 dedicated screens; shared filter/stat
  widgets extracted. No schema. Refunds now net into reported revenue.
- [x] **Refunds / returns** — DONE 2026-06-22 `b8dc821` (offline-first, partial,
  optional restock). Migration `033` (NOT yet applied live). See the Refunds
  block below — restock rides existing ledgers, no new RPC. 6 tests.
- [x] **Offline v2 Phase D — partial** 2026-06-22 `98a5279`: Drift indexes,
  sync-health view, post-reconnect JWT refresh, SECURITY DEFINER audit (mig
  `034`). See the Phase D section for what's still deferred.
- [ ] **Apply migrations `033` + `034` to the live project** (gated — MCP/SQL
  editor). Then **verify on device/web + CodeRabbit pass** before pushing.
- ECC agent harness installed globally (passive: 67 agents / 198 skills / 92
  commands; hooks NOT wired). WASM-SQLite-on-web considered, **deferred** (web
  stays online-only; phone is the offline-first target).

---

## Wholesale support (NEW — retail/wholesale split)

shop_type chosen at onboarding, locked. `shopTypeProvider.isWholesale` is the gate.

- [x] Onboarding: business-type selection step (retail vs wholesale), saved to
  `shop_settings.shop_type`. Onboarding is now 5 steps.
- [x] Mandatory customer on every sale (wholesale) — new-sale `_submit` gate +
  "required" cue on the picker.
- [x] Custom units of measurement (both types) — inline "New unit" in product form.
  Online-only create; ponytail shortcut (offline add deferred).
- **Batch numbers + expiry (wholesale)** — ✅ FEATURE-COMPLETE for pilot, on
  branch `feat/batch-tracking`. Migrations `028`/`029`/`030` all applied live (via
  MCP). Decisions (2026-06-21): auto-FEFO, expired = warn-but-allow, recall
  traceability IN (`sale_item_batches`), retail untouched. **Unverified end-to-end
  — needs a wholesale shop exercised on a device.**
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
  - [x] **Phase 3 — FEFO depletion on sale.** Immutable-batch / append-only
    ledger model: `product_batches.quantity` = received (never mutated);
    depletion lives in `sale_item_batches`; `remaining = received − Σsib`;
    rollup = `Σreceived − Σsib`. Migration `029` (applied): batch-aware rollup +
    BATCH-LEVEL conflict detection (a lot can go negative while the product total
    stays positive) + sale RPC `p_item_batches` + wholesale void = soft-delete
    the ledger. Local: `LocalSaleItemBatches` (schema v13) + pull descriptor;
    `createSale(useBatches)` FEFO-allocates + writes ledger + recomputes rollup;
    void reverses locally; SyncService passes allocations; expired-lot warn-but-
    allow dialog. Pure FEFO allocator + 14 tests. **Unverified end-to-end** (needs
    a wholesale shop on device).
  - [x] **Phase 4 — surface expiry + lot disposal.** Inventory action sheet shows
    a BATCHES section per wholesale product: each lot's batch number, expiry
    (Expired / Expiring-soon ≤30d badges), and remaining qty, FEFO-ordered.
    `productBatchesProvider`. **Discard lot** (`030`): soft-delete a lot
    (expired/damaged) → rollup drops exactly its remaining; owner-gated
    (`settings.manage`); offline-first (pushes the soft-delete). `030` also fixed
    the rollup to ignore discarded lots' depletions and **auto-closes a batch
    conflict** when the lot's remaining recovers (owner re-adds stock) or is
    discarded — so detection (`029`) has a close path without a bespoke screen.
    Schema v14. Tests: discard restates the rollup. 149 tests pass.
  - [x] **Partial lot correction — DONE 2026-06-22** (`032` `batch_adjustments`).
  - [x] **Per-lot details incl. "added by" — DONE 2026-06-22** (`031`).
  - [ ] **Still deferred (post-pilot):** (a) bespoke batch-conflict resolution
    screen — current path is add-stock/correct-to-recover + auto-close. (b) Recall
    report ("which customers got lot X") — server query over `sale_item_batches`;
    will live on the **Reports** screen. Rare for single-device pilot shops.
- [x] **Refunds / returns — DONE 2026-06-22** `b8dc821`. Offline-first, partial
  (per item/qty), optional restock per refund. Migration `033` adds branch_id +
  restock + sync metadata to `refunds`/`refund_items` and wires them into the
  replica model. Restock reuses existing idempotent ledgers (retail: additive
  `'restock'` inventory_adjustment; wholesale: negative `batch_adjustments` on
  the original lots via the pure `allocateRestock` FEFO-reverse). Over-refund
  capped app-side. Refunds net out of reported revenue. Drift v17. Entry point:
  Refund action on SaleDetailScreen (`refund_own`/`refund_any` gated).
  **`033` NOT yet applied live; unverified on device.** Deferred: refund
  payment-method (only the cash-reconciliation feature needs it).
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

Phases A–C complete. 2026-06-22 `98a5279` did 4 of 6:
- [x] Indexes on local Drift (`is_synced`, FKs, shop/branch) — `_createPerformanceIndexes`,
  fresh-create + v17→v18 upgrade. (Local mirror has no `updated_at`; that's server-side.)
- [x] Offline JWT refresh on reconnect — `SyncService.sync()` refreshes an expired
  access token before the first push so it doesn't 401 and get swallowed.
- [x] Operator sync-health view — Settings sync card shows pending-push count
  (`pendingPushCountProvider`) + last sync outcome. (`local_refunds` added to the
  pending-work watcher.)
- [x] Audit SECURITY DEFINER functions — done; only finding was `handle_new_user()`
  with a mutable `search_path` → migration `034` pins it. No dynamic-SQL surface.
- [ ] **First-pull pagination + on-device retention policy** — DEFERRED. Data-loss-
  adjacent (dropping local history); deserves its own focused session + device test.
- [ ] SQLCipher for the local cache — still deferred past pilot (see Security below).

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
