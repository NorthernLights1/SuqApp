# Current State — Suq ERP

Last updated: 2026-06-06 (session 14)

---

## What We Are Building

**Suq** — mobile ERP for small shop owners. Flutter + Supabase.
Package: `com.temesgen.suq` | Repo: `NorthernLights1/SuqApp`
Flutter app root: `c:/Projects/SuqApp/`
Active branch: `feat/notifications`
Push: `git push origin feat/notifications`

---

## Current Phase

**Phase 5 complete. Session 6 fixed 3 bugs + a dependency regression.**

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

---

## What Works Right Now

- `flutter analyze` — 0 issues ✅ (last run 2026-06-06, session 13)
- `flutter test` — 96 tests passing ✅ (last run 2026-06-03)
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

## Notifications (Session 13)

**Edge Function**: `dispatch-notifications` (ACTIVE, v1) — handles both notification types in one function.

**Low-stock alerts**:
- Triggered automatically after every completed sale (fire-and-forget in `CreateSaleNotifier._checkLowStock`)
- Queries `inventory JOIN products` for all shop branches, filters where `quantity <= low_stock_threshold`
- Skips silently if no products are below threshold or if no channels configured

**Overdue credit alerts**:
- Triggered manually via "Send Overdue Credit Reminders Now" button in Settings screen
- Queries `sales` where `is_credit=true AND credit_settled_at IS NULL AND created_at < now() - overdue_days`
- `overdue_credit_days` is a shop setting (default 7)

**Delivery channel**: Email via **Resend** API (v2 — Telegram removed, deferred).
- Requires `RESEND_API_KEY` Supabase secret + `notification_email` in shop_settings
- Owner's domain can be used as sender by verifying it in Resend + adding DNS records in Cloudflare

**Shop settings keys added** (`SettingKeys`):
- `notification_email` — destination email address
- `overdue_credit_days` — integer, days before credit is overdue (default 7)

**Setup required** (one-time):
- Sign up at resend.com → get API key → add as Supabase secret `RESEND_API_KEY`
- Optionally verify own domain in Resend → update `from` address in Edge Function

All notifications logged to `notification_logs` table with `sent`/`failed` status.

---

## Staff Invite Flow (Edge Function v4 — session 12)

1. Owner taps "Invite Staff" FAB → enters email + role
2. App calls `invite-staff` Edge Function v4 (deployed, ACTIVE)
3. Function verifies caller via `shop_users` (role_id = owner UUID, status = active)
4. Checks `listUsers` for existing email:
   - Already in this shop → returns 400 with clear message
   - Exists but not in shop → inserts `shop_users` with `status='active'` (no email sent), returns `existing: true`
   - New email → `auth.admin.inviteUserByEmail` + inserts `shop_users` with `status='invited'`, returns `existing: false`
5. Flutter shows: "Invite email sent to X" or "X already has an account — added to your shop directly"
6. Staff receives invite email → sets password → opens app
7. Router routes non-owner with `shop_users` record to dashboard (not onboarding)
8. `shop_users.status` updated `invited` → `active` on first login

---

## Cost Price / Gross Profit

- `products.cost_price` (nullable NUMERIC 12,4) — set in product form
- `sale_items.cost_price_snapshot` — captured at sale time for historical accuracy
- Reports show gross profit only when at least one item in the period has cost data

---

## Supabase Architecture

**RLS**: Two-layer — PostgreSQL grants + RLS policies (both required).
- `is_shop_member(shop_id)` — most tables
- `shop_id_from_branch(branch_id)` — branch-scoped tables
- `anon` revoked from all 4 internal functions; `authenticated` revoked from `handle_new_user` and `rls_auto_enable`

**shop_users schema**: id, shop_id, branch_id (nullable), user_id, role_id (FK→roles), status ('active'/'invited'/'suspended'), invited_by, created_at

**roles**: owner=`000...0001`, manager=`000...0002`, cashier=`000...0003`

**Edge Functions**: `invite-staff` — deployed and ACTIVE

**shop_settings**: `inventory_mode` = `"strict"` (updated session 4 via SQL; onboarding default also changed to `"strict"`)

---

## Drift / Offline Architecture (Phase 5)

**Local DB**: `lib/data/local/app_database.dart` — tables: LocalProducts, LocalStock, LocalSales, LocalSaleItems, LocalCustomers.

**Write path (sales)**: `SalesRepository.createSale` → write to Drift (`isSynced=false`) + update local stock → fire-and-forget Supabase push → on success `markSaleSynced`.

**Read path (sales)**: Drift first, fallback to Supabase if local is empty.

**Seed**: `SeedNotifier` watches shop, seeds products/stock/customers to Drift on first load. NOTE: `seedNotifierProvider` is defined but never watched in the UI — seeding does not trigger automatically yet.

**Sync**: `SyncService._pushPendingSales` pushes unsynced sales to Supabase; handles duplicate-key gracefully.

**Web**: `appDatabaseProvider` returns `null` on web (`kIsWeb`). All callers null-guarded. Falls back to Supabase-direct.

**NOT offline-first yet**: inventory writes (product create/edit, stock adjustments), expenses, customer edits.

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

- Inventory writes (create/edit product, stock adjust) not write-through to Drift
- Hardcoded strings throughout screens violate l10n rule (`app_en.arb` not used)
- No error boundaries — raw Supabase exceptions reach snackbars
- `SyncService` not auto-triggered on connectivity change (must call `.sync()` manually)
- Permission cache TTL not implemented (role changes need app restart)
- `Decimal.parse()` without try-catch in models — can throw on malformed DB data
- Inventory writes (create/edit product, stock adjust) not write-through to Drift
- `FilteringTextInputFormatter` allows multiple decimal points (e.g. "1.2.3") — `Decimal.tryParse` returns null and validation catches it, but a smarter formatter could reject mid-input
