# Current State — Suq ERP

Last updated: 2026-06-22

---

## What We Are Building

**Suq** — mobile ERP for small shop owners. Flutter + Supabase.
Package: `com.temesgen.suq` | Repo: `NorthernLights1/SuqApp`
Flutter app root: `c:/Projects/SuqApp/`
Active branch: `feat/batch-tracking` (wholesale batch/expiry + per-lot details +
correction). Cut from `feat/wholesale-support` ← `feat/action-feedback`.
`security` merged to `main` (PR #1). `offline-first_v2` merged to `main` (PR #4).
Push: `git push origin <branch>` — NOT pushed yet (awaiting CodeRabbit pass).

## Build & Distribution
- APK built on GitHub Actions (`.github/workflows/build-apk.yml`, manual
  workflow_dispatch). Needs repo secrets `SUPABASE_URL` + `SUPABASE_ANON_KEY`.
  Release build is debug-signed (pilot sideloading, not Play Store).
- Android main manifest carries the INTERNET permission (release APKs need it
  declared there, not just debug/profile).

---

## Current Phase

**Session 20 in progress on `feat/action-feedback`.**

| Phase | Status |
|---|---|
| Phase 0 — Bootstrap + SQL migrations | ✅ Done |
| Phase 1 — Core services | ✅ Done |
| Phase 2 — Auth, Onboarding, Dashboard shell | ✅ Done |
| Phase 2.5 — Inventory form bug fix + UI modernisation | ✅ Done |
| Phase 3 — Sales module | ✅ Done |
| Phase 4 — Customers, Expenses, Reports, Staff, Settings | ✅ Done |
| Phase 5 — Drift offline DB + tests | ✅ Done (sales offline-first; inventory/expenses still Supabase-direct) |
| Session 4 — Inventory enforcement + screen overhaul | ✅ Done |
| Session 5 — Unit tests (81 passing), 4 bug fixes | ✅ Done |
| Session 6 — Credit customer search fix, Receive Payment flow, dep revert | ✅ Done |
| Session 7 — Remove inventory mode toggle, wire seed auto-trigger | ✅ Done |
| Session 8 — Riverpod 3.x + go_router v17 + google_fonts v8 + connectivity_plus v7 migration | ✅ Done |
| Session 9 — Stock correction bug fix, credit reconciliation, report year/custom/category, inventory category filter | ✅ Done |
| Session 10 — Inventory correction unit test suite (15 tests) | ✅ Done |
| Session 11 — Credits tab, sale color-coding, detail screen enhancements, post-sale refresh fix | ✅ Done |
| Session 12 — ListTile warnings, RenderFlex overflow, staff invite v4 (403 fix + duplicate check) | ✅ Done |
| Session 13 — Notifications phase: low-stock + overdue-credit alerts via email (Resend) and Telegram | ✅ Done |
| Session 14 — CodeRabbit review: null-safety fix + explicit branch_id in settings upsert | ✅ Done |
| Session 15 — Auto-sync triggers, per-credit partial settlement + payment history (mig 017/018), add-stock fields | ✅ Done |
| Session 16 — GitHub Actions APK build, APK debug-build fixes (env secrets, INTERNET perm), security branch (licensing) | ✅ Done |
| Session 17 — Test-feedback batch (12 items): server-first sales reads, cashier name, reports RBAC + drill-downs, offline boot, inventory refresh, honest overdue-email, email-all recipients (fn v5) | ✅ Done (merged to main) |
| Session 18 — Licensing merged to main; overdue-email = all unpaid (fn v6); offline-first Phases 1–3 (download/pull sync, all reads local-first, oversell conflict detection+resolution+email) | ✅ Done (merged to main via PR #4 in session 19) |
| Session 19 — Device testing: 9 bugs found. Fixed: Bug 7 (UTC sync), Bugs 1,4,5,6,10,12 (void message, offline product/category creation, reports local-first), Bugs 8+9 (friendly offline/wrong-password login error + cached session usable offline). Schema v11. Bug 11 confirmed not a bug. Code cleanups. | ✅ Merged (PR #4) |
| Session 20 — Action feedback: success/error snackbars on all write operations (expenses, add stock, correct stock, product save/update, product deactivation). Fixed pre-existing bug where credit settle sheet always closed even on failure. | 🚧 On branch `feat/action-feedback` |

---

## What Works Right Now

- `flutter analyze` — 0 issues ✅ (last run 2026-06-22)
- `flutter test` — 161 tests passing ✅ (last run 2026-06-22)
- Auth (signup/login/logout) ✅
- Onboarding: shop + branch creation + default settings ✅
- Dashboard: home summary, sales tab (color-coded), inventory tab, **credits tab**, more tab ✅
- **Inventory: unified product+stock list (tabs removed), strict enforcement, Add Stock / Correct Stock flows** ✅
- ProductFormScreen: all fields including cost_price, opening stock required on create ✅
- Sales: new sale, cart, payment methods (Cash/Bank/Credit), credit customer, void ✅
- **Sales: strict inventory enforcement — block if not in inventory OR insufficient stock** ✅
- **Sales: credit customer name search fixed** ✅
- Customers: list, credit balance, transaction history, add/edit ✅
- **Customers: Receive Payment dialog — partial or full credit settlement** ✅
- **Credits tab: dedicated bottom nav tab, per-bill settlement with Cash/Bank Transfer + notes** ✅
- Expenses: record expense, category, date filter ✅
- Reports: today/week/month, sales summary, gross profit, expense breakdown, low-stock ✅
- Settings: branch name edit ✅; inventory mode toggle removed (enforcement is unconditional, no UI for it)
- Staff: member list, suspend/restore, invite via email (Edge Function) ✅

---

## Retail vs Wholesale (shop_type) — NEW

Suq now serves two business types, chosen at onboarding and **locked** afterward
(pricing implications deferred).

- **`shop_type` shop_setting** (`'retail'` | `'wholesale'`), written during shop
  creation in `OnboardingNotifier.createShop`. Onboarding step 1 ("What kind of
  business?") selects it before naming the shop; onboarding is now **5 steps**.
- **`shopTypeProvider`** (`features/settings/.../shop_type_provider.dart`) —
  FutureProvider reading the setting; local-cache fallback offline. Extension
  `AsyncValue<String>.isWholesale` is the gate any feature uses:
  `if (ref.watch(shopTypeProvider).isWholesale) ...`.
- **Gated so far:** mandatory customer on every sale (wholesale) — the new-sale
  `_submit` blocks a customer-less sale when wholesale; the customer picker shows
  "(required)". Retail keeps customer optional (still required for credit).
- **Custom units of measurement** (both types): "New unit" inline in the product
  form unit picker → `InventoryRepository.createMeasurementUnit` (remote create +
  optimistic local mirror; `measurement_units` already shop-scoped + in delta pull).
  Online-only create (ponytail: reference data, added rarely while connected).
- **Batch tracking FEATURE-COMPLETE (Phases 1–4 + the 2026-06-22 follow-ups),
  unverified on a device.** Immutable batches + append-only ledgers;
  `remaining = received − Σ(sale_item_batches) − Σ(batch_adjustments)`; the
  rollup is the same minus the product total. Migrations `028`–`032` all applied
  live via MCP. `029`: batch-aware rollup + **batch-level conflict detection** +
  sale RPC `p_item_batches` + wholesale void = soft-delete ledger. `030`: lot
  discard + conflict auto-close. `031`: `product_batches.created_by` ("added by").
  `032`: `batch_adjustments` per-lot correction ledger (rollup/conflict gain the
  adjustment term, preserving 030). Sale draws soonest-expiry-first; expired =
  warn-but-allow. **Schema v16. 154 tests pass.**
- **2026-06-22 wholesale follow-ups (this session, all committed, unpushed):**
  - #1 batch/lot number REQUIRED at first stock-in (wholesale) `384c620`.
  - #2 **Batch details page** (`product_batch_detail_screen.dart`): per-lot card —
    batch #, expiry, remaining, received qty, added-on, **added-by** (`031`) `6d684ee`.
  - #3 **per-lot correction** (counted qty + reason → `batch_adjustments`, audit
    trail; lowers remaining + stock + sellable) + **add-batch** action `905ad18`.
  - Plus the BLOCK-MERGE review fixes `1365841` (v14 migration crash guard,
    atomic createSale, no-lot guard, rollup clears stale expiry) and a web
    fallback for batch reads `8ff3b48` (Chrome has no local DB).
- **Deferred (post-pilot, rare):** bespoke batch-conflict resolution screen,
  recall report ("which customers got lot X" — server query over
  `sale_item_batches`; tracked, will live on the **Reports** screen).
- **Next:** #4 reports segregation (Sales / Inventory / Expenses / Revenue — no
  schema). Then refunds (couples to batches), extra customer fields.

---

## 2026-06-22 (later session) — Reports segregation + Refunds + Phase D

All three committed locally on `feat/batch-tracking`, UNPUSHED. Migrations `033`
+ `034` + `035` **applied live** 2026-06-22 (no prod users). Schema **v18**. 161 tests.
(`035` = post-apply advisor follow-up revoking RPC EXECUTE on batch trigger fns.)

- **Reports segregation (#4) — DONE** `c17c0d1`. Reports is now a **card hub**
  (period selector + 4 tappable cards) opening dedicated **Sales / Inventory /
  Expenses / Revenue** screens. Shared period/category/stat widgets extracted to
  `reports/.../widgets/report_filters.dart`. Reuses `reportSummaryProvider` /
  `stockLevelsProvider` — no schema/provider change, still offline-first.
- **Refunds — DONE (offline-first, partial, optional restock)** `b8dc821`.
  Migration `033` wires the dormant `refunds`/`refund_items` tables into the
  replica model (+`branch_id`, +`restock`, +sync metadata). Partial (per
  item/qty), local-first (`isSynced=false`, SyncService sole pusher), delta-pull
  back, over-refund capped app-side (`refundedQtyBySaleItem`). **Restock rides
  existing idempotent ledgers — no new RPC:** retail → additive `'restock'`
  inventory_adjustment; wholesale → negative `batch_adjustments` on the lots the
  line drew from (pure FEFO-reverse allocator `allocateRestock`). Refunds net out
  of reported revenue (local + web). Drift v17 (+LocalRefunds/LocalRefundItems).
  Entry: **Refund** action on SaleDetailScreen (gated `refund_own`/`refund_any`).
  `lib/features/refunds/`. 6 tests. ponytail: no refund payment-method picker
  (only the deferred cash-reconciliation needs it).
- **Offline v2 Phase D — partial** `98a5279`. DONE: (a) hot-path Drift **indexes**
  (is_synced/FK/shop-branch) on fresh-create + v17→v18 upgrade; (b) **sync-health**
  in Settings sync card (pending-to-upload count + last sync outcome;
  `pendingPushCountProvider`; `local_refunds` added to the pending-work watcher);
  (c) **JWT refresh** before the first post-reconnect push (don't 401-and-swallow);
  (d) **SECURITY DEFINER audit** → migration `034` pins `search_path` on
  `handle_new_user()` (last mutable-path definer fn; no dynamic-SQL surface
  found). DEFERRED with reasons: first-pull pagination/retention
  (data-loss-adjacent — own session); SQLCipher (already past-pilot).
- **Pending live steps:** apply migrations `033` + `034` to the live project;
  CodeRabbit pass; device verification of refunds (retail + wholesale restock).

---

## Inventory Enforcement Logic (Session 4 final)

Three cases, evaluated at sale time against `inventory` table:

| Situation | Result |
|---|---|
| Product not in `inventory` table | Blocked — "X is not in inventory. Add stock before selling." |
| Product in inventory, stock < quantity | Blocked — "Not enough stock for X. Available: N unit" |
| Product in inventory, stock ≥ quantity | Allowed — stock deducted, `inventory_adjustments` record written |

Applies on both native (local DB pre-check in `SalesRepository`) and web (Supabase check in `SalesRemote`).

---

## Inventory Stock Operations (Session 4)

Two operations allowed:
1. **Add Stock** (tap product → "Add Stock") — additive. Writes `opening_stock` (first entry) or `restock` to `inventory_adjustments`. No password needed.
2. **Correct Stock** (tap product → "Correct Stock") — absolute quantity override. Requires owner's login password verified via `supabase.auth.signInWithPassword`. Writes `correction` to `inventory_adjustments`.

Product detail edit: tap product → "Edit Product Details" → `ProductFormScreen`.

---

## Credit Settlement Flow (Session 6)

"Mark Settled" button replaced with **"Receive Payment"** on `CustomerDetailScreen`.
- Dialog pre-fills with full outstanding balance
- Owner can enter any amount: partial reduces balance, full (≥ balance) zeros it out
- Uses `CustomerFormNotifier.receivePayment(customerId, amount)` — fetches current balance, subtracts, updates
- Returns to customer list on success (list auto-refreshes via `ref.invalidate(customersProvider)`)

---

## Credits Tab (Session 11)

Bottom nav: Home / Sales / Inventory / **Credits** / More. Customers moved to More tab.

- `CreditsScreen` — shows only customers with unsettled credit bills, grouped alphabetically
- Each bill card: amount, date, **Details** button (fetches full sale → `SaleDetailScreen`), **Settle** button
- Settle sheet: selects Cash or Bank Transfer; Bank Transfer reveals optional notes field
- `outstandingCreditProvider` — fetches all unsettled credit sales joined with `customers(id, name, phone)`
- `settleCreditSale` — requires `settlementMethod` ('cash'|'bank_transfer'), optional `settlementNotes`
- `receivePayment` — auto-settles all outstanding bills when balance reaches zero
- `showCreditSettleSheet()` — public helper shared with `CustomerDetailScreen`
- DB columns added: `sales.credit_settlement_method`, `sales.credit_settlement_notes`

## Sales Color Coding + Detail Screen (Session 11)

**Color coding** (both Sales screen and Dashboard Sales tab):
- Cash → blue receipt icon
- Unsettled credit → orange credit card icon + "Credit" badge; subtitle shows customer name
- Settled credit → green checkmark icon + "Paid" badge
- Voided → red cancel icon + "Voided" badge

**SaleDetailScreen** now shows:
- Transaction ref (`#` + last UUID segment)
- Payment row: "Cash", "Credit — Outstanding" (warning), "Credit — Settled (Cash/Bank Transfer)" (success)
- Customer card (name + phone) for credit sales
- Settlement Notes card for bank transfer settlements with notes
- Outstanding credit banner at top if unsettled

**Sale model** additions (nullable, populated from Supabase join, null in local Drift path):
- `customerName`, `customerPhone` — from `customers(id, name, phone)` join
- `paymentMethodName` — from `payment_methods(id, name, code)` join
- `creditSettlementMethod`, `creditSettlementNotes` — from `sales.*`

**Bug fixed**: `CreateSaleNotifier.submit` now invalidates `salesListProvider` (always) and `outstandingCreditProvider` (credit sales). Sales and Credits tabs now refresh immediately after a new sale without restart.

---

## Notifications — SCHEDULED model (Session 16, replaces per-sale)

**Edge Function `cron-notifications`** (ACTIVE, v2, `verify_jwt:false`) — the live path.
- Runs on a **server-side schedule** (pg_cron), NOT triggered by the app. Works app-closed.
- **Two pg_cron jobs**: `low-stock-am` (`0 6 * * *`) + `low-stock-pm` (`0 18 * * *`) UTC = **9 AM & 9 PM EAT**. They `net.http_post` the function, passing the Vault `cron_secret`.
- Auth: function is public but gated — reads `x-cron-secret` header, verifies via `public.verify_cron_secret(text)` (SECURITY DEFINER, reads Vault). Secret stored in `vault` as `cron_secret`.
- Loops **all shops**; recipients = **owner's auth email (DEFAULT)** + optional `notification_email` shop setting. Owner-default removed the old "no notification email" 400.
- Sends **one combined digest** per shop: LOW STOCK section (`inventory JOIN products` where `quantity <= low_stock_threshold`) + OVERDUE CREDITS section (`sales` is_credit, unsettled, completed, older than `overdue_credit_days`, default 7). Each section only if non-empty; no email if both empty.
- Email via **Resend** from `notifications@massivedynamic.dev` (verified domain). `RESEND_API_KEY` secret is SET. Logged to `notification_logs`.

**Old per-sale path REMOVED**: `CreateSaleNotifier._checkLowStock` deleted from `sales_provider.dart` (was spammy). `dispatch-notifications` (v3) still deployed and powers the manual "Send Overdue Reminders Now" button in Settings only.

**Settings**: notification email field relabeled "Additional notification email (optional)" (owner always notified).

**Migration 016** holds the portable DB pieces (extensions + `verify_cron_secret`); Vault secret + cron jobs + function are env-specific (documented in 016 comments).

---

## Staff Invite Flow — CODE-BASED (Session 16, no link/hosting/deep-link)

Why changed: email magic-links require a hosted landing page + mobile deep links.
Replaced with an in-app email-code (OTP) flow that works identically on web & mobile.

1. Owner taps "Invite Staff" → email + role → `invite-staff` v10.
2. v10 verifies caller is active owner (shop_users + owner role). For a NEW email it
   `admin.auth.admin.createUser({email, email_confirm:true})` (NO email sent) +
   inserts `shop_users` status='invited'. Existing user not in shop → added active.
   (So only invited emails have an account → only they can request a code.)
3. Staff opens app → **"I was invited"** button (login screen) → `AcceptInviteScreen`
   (`/accept-invite`, allowed logged-out): enter email → **Send code**
   (`auth.signInWithOtp(shouldCreateUser:false)`) → enter code + full name + password
   + confirm → **Create account** (`verifyOTP` → `updateUser(password, full_name)` +
   `profiles` upsert).
4. Router: on first sign-in, invited→active via `rpc('activate_my_membership')`
   (SECURITY DEFINER; shop_users is owner-write-only so staff can't self-update).
5. **ONE-TIME SETUP REQUIRED**: Supabase → Auth → Email Templates → **Magic Link** must
   include `{{ .Token }}` so the code (not a link) is emailed.

Auth methods live in `AuthNotifier`: `sendInviteCode()`, `claimInvite()`.

---

## Cost Price / Gross Profit

- `products.cost_price` (nullable NUMERIC 12,4) — set in product form
- `sale_items.cost_price_snapshot` — captured at sale time for historical accuracy
- Reports show gross profit only when at least one item in the period has cost data

---

## Supabase Architecture

**API keys**: project migrated to NEW key system — `sb_publishable_...` (anon) + `sb_secret_...` (service_role). Legacy JWT keys not used. Edge functions get `sb_secret` as `SUPABASE_SERVICE_ROLE_KEY`.

**service_role grants**: migration 013 RESTORED `SELECT/INSERT/UPDATE/DELETE` to `service_role` on ALL public tables (+ default privileges). A prior blanket REVOKE had stripped them, which (once the sb_secret key exposed it) made every Edge Function admin query fail "permission denied" → invite-staff & dispatch-notifications returned 403 on the owner-check. service_role is server-only so this doesn't weaken RLS.

**RLS**: Two-layer — PostgreSQL grants + RLS policies (both required).
- `private.is_shop_member(shop_id)`, `private.shop_id_from_branch(branch_id)` — SECURITY DEFINER helpers
- `private.shares_shop_with(user_id)` (migration 014) — lets `profiles_select` policy expose name/phone to shopmates (staff list shows real names instead of "Unknown")
- `public.activate_my_membership()` (015), `public.verify_cron_secret(text)` (016)

**shop_users schema**: id, shop_id, branch_id (nullable), user_id, role_id (FK→roles), status ('active'/'invited'/'suspended'), invited_by, created_at. RLS: owner-write-only (`shop_users_write`), select = own row OR shop owner.

**roles**: owner=`000...0001`, manager=`000...0002`, cashier=`000...0003`

**Edge Functions (ACTIVE)**: `invite-staff` (v10, createUser+OTP), `cron-notifications` (v2, scheduled digest), `dispatch-notifications` (v3, manual overdue button only), `test-email` (inert/410 diagnostic — deletable).

**Extensions**: `pg_cron`, `pg_net`, `supabase_vault` enabled (for scheduled notifications).

**shop_settings**: `inventory_mode` = `"strict"` (updated session 4 via SQL; onboarding default also changed to `"strict"`)

---

## Drift / Offline Architecture (Phase 5)

**Local DB**: `lib/data/local/app_database.dart` — tables incl. LocalProducts,
LocalStock, LocalProductBatches, LocalSaleItemBatches, **LocalBatchAdjustments**,
LocalSales, LocalSaleItems, **LocalRefunds, LocalRefundItems**, LocalCustomers.
Schema **v18** (v12 batches, v13 sale-item-batches ledger, v14 batch `deletedAt`,
v15 batch `createdBy`, v16 `local_batch_adjustments`, **v17 refunds/refund_items,
v18 hot-path performance indexes**). **Migration-guard caveat:** batch-table `addColumn`
steps are guarded `from >= 12` because the v12 `createTable` already builds the
current schema (a <12 upgrade must not re-add the column — see the v14/v15 steps).

**Batch tracking (wholesale) — Phases 1–4 + per-lot correction DONE**:
`product_batches` (server) holds qty/expiry/batch/created_by per lot;
`sale_item_batches` = depletion ledger; `batch_adjustments` = correction ledger.
Triggers keep `inventory.quantity = Σreceived − Σdepletions − Σcorrections`.
Device mirrors all three via delta pulls. Retail untouched (no batches).

**Write path (sales)**: `SalesRepository.createSale` → write to Drift
(`isSynced=false`) + update local stock. No inline push (offline-first v2 single
boundary): `SyncService` is the sole pusher; a debounced pending-work watcher
nudges a sync, which pushes via the `upsert_sale_with_inventory` RPC.

**Read path**: local-first, not local-fallback (see DECISIONS.md "Offline-first
v2"). Reads return from the local Drift mirror immediately; the network is never
on the user-visible path. Remote is consulted only when the local cache can't
answer (e.g. a sale older than the sync window, or web with no local DB).

**Seed / pull**: `SeedNotifier` watches shop (watched in `dashboard_screen.dart`)
and seeds on login; `SeedService` uses a **delta pull engine** — per-table cursor
in `LocalSyncState`, fetches only rows where `updated_at >= cursor`, upserts live
rows, hard-deletes soft-deleted rows, then advances cursor. First pull is full
(366-day / 2000-row window for sales/expenses). 13 `_seedX` methods are the registry.

**Sync**: `SyncService` bulk-upserts all pending entities in FK order:
customers → sales + sale_items → expenses → credit payments → products → product
categories. All writes are `upsert(onConflict:'id')` (idempotent). Stock
adjustments remain per-row (server-side delta accumulator).

**Web**: `appDatabaseProvider` returns `null` on web (`kIsWeb`). All callers null-guarded. Falls back to Supabase-direct.

**NOT offline-first yet**: product/category *edits* (updateProduct is still remote-only), stock adjustments are already offline-first. Product and category *creation* is offline-first as of schema v11.

**Tests**: `test/data/local/app_database_test.dart` — unit tests for all DB ops using `NativeDatabase.memory()`.

---

## Dependencies (current versions — session 8)

- `flutter_riverpod: ^3.3.1` — migrated from 2.x. All `StateProvider`/`StateNotifier` replaced with `Notifier` + `NotifierProvider`. All `.valueOrNull` replaced with `.asData?.value`.
- `go_router: ^17.2.3` — migrated from v14. No code changes needed (API is backward-compatible in this codebase).
- `google_fonts: ^8.1.0` — upgraded from v6.
- `connectivity_plus: ^7.1.1` — upgraded from v6 (code was already using v7 list API).
- `riverpod_annotation: ^4.0.2`, `riverpod_generator: ^4.0.3` — upgraded to match Riverpod 3.x.
- `custom_lint` and `riverpod_lint` — **removed** (analyzer version conflict between riverpod_lint 3.x and custom_lint 0.8.x; not yet resolved upstream). Add back when `custom_lint 0.9+` resolves the conflict.

---

## Known Tech Debt

- Product/category **edit** (updateProduct) still remote-only; create is now offline-first
- Hardcoded strings throughout screens violate l10n rule (`app_en.arb` not used)
- No error boundaries — raw Supabase exceptions reach snackbars
- Permission cache TTL not implemented (mid-session role changes still need an
  app restart). 2026-06-22: hardened so it never caches an EMPTY result and
  refreshes on onboarding finish — fixed "new owner stuck at cashier-level".
- `Decimal.parse()` without try-catch in models — can throw on malformed DB data
- `FilteringTextInputFormatter` allows multiple decimal points (e.g. "1.2.3") — `Decimal.tryParse` returns null and validation catches it, but a smarter formatter could reject mid-input
- Expenses & customers push as bulk upsert — a single invalid row blocks that batch (sales/adjustments/credit payments already per-row failure-isolated)
- Presentation providers call Supabase directly (bypasses "modules behind interfaces" rule) — app-wide cleanup, not per-feature

---
*Related: [[INDEX]] · [[OPEN_TASKS]] · [[DECISIONS]] · [[BUGS_AND_FIXES]] · [[FILE_MAP]]*
