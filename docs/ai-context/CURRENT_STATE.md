# Current State — Suq ERP

Last updated: 2026-06-12 (session 17)

---

## What We Are Building

**Suq** — mobile ERP for small shop owners. Flutter + Supabase.
Package: `com.temesgen.suq` | Repo: `NorthernLights1/SuqApp`
Flutter app root: `c:/Projects/SuqApp/`
Active branch: `offline-first` (in progress). `security` merged to `main` (PR #1)
then deleted. `main` holds the licensing system + session-17 fixes.
Push: `git push origin <branch>`

## Build & Distribution
- APK built on GitHub Actions (`.github/workflows/build-apk.yml`, manual
  workflow_dispatch). Needs repo secrets `SUPABASE_URL` + `SUPABASE_ANON_KEY`.
  Release build is debug-signed (pilot sideloading, not Play Store).
- Android main manifest carries the INTERNET permission (release APKs need it
  declared there, not just debug/profile).

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
| Session 15 — Auto-sync triggers, per-credit partial settlement + payment history (mig 017/018), add-stock fields | ✅ Done |
| Session 16 — GitHub Actions APK build, APK debug-build fixes (env secrets, INTERNET perm), security branch (licensing) | ✅ Done |
| Session 17 — Test-feedback batch (12 items): server-first sales reads, cashier name, reports RBAC + drill-downs, offline boot, inventory refresh, honest overdue-email, email-all recipients (fn v5) | ✅ Done (merged to main) |
| Session 18 — Licensing merged to main; overdue-email = all unpaid (fn v6); offline-first Phases 1–3 (download/pull sync, all reads local-first, oversell conflict detection+resolution+email) | 🚧 Built, pending on-device verify + merge (branch `offline-first`) |
| Session 15 — Code review: 9 findings fixed (atomic upsert, CHECK constraint, false-success snackbar, unsafe cast, INotificationService wiring, Telegram flag, stale controllers, regex, raw error) | ✅ Done |
| Session 16 — service_role grant fix, UTC date fix, code-based staff invite, profiles shopmate read, scheduled 9am/9pm notifications (low-stock + overdue) | ✅ Done |

---

## What Works Right Now

- `flutter analyze` — 0 issues ✅ (last run 2026-06-09, session 16)
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

**Local DB**: `lib/data/local/app_database.dart` — tables: LocalProducts, LocalStock, LocalSales, LocalSaleItems, LocalCustomers.

**Write path (sales)**: `SalesRepository.createSale` → write to Drift
(`isSynced=false`) + update local stock. No inline push (offline-first v2 single
boundary): `SyncService` is the sole pusher; a debounced pending-work watcher
nudges a sync, which pushes via the `upsert_sale_with_inventory` RPC.

**Read path**: local-first, not local-fallback (see DECISIONS.md "Offline-first
v2"). Reads return from the local Drift mirror immediately; the network is never
on the user-visible path. Remote is consulted only when the local cache can't
answer (e.g. a sale older than the sync window, or web with no local DB).

**Seed / pull**: `SeedNotifier` watches shop (watched in `dashboard_screen.dart`)
and seeds on login; `SeedService.seedAll` is a full download (shop, branches,
settings, payment methods, categories, units, profiles, products, stock,
customers, sales+items, expenses, credit payments) and also runs on every sync
trigger via `SyncScheduler` (push then pull).

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
- ~~`SyncService` not auto-triggered on connectivity change~~ STALE — `SyncScheduler`
  already fires on offline→online edge + 15-min backstop + cold start (verified
  2026-06-14 reading the code)
- Permission cache TTL not implemented (role changes need app restart)
- `Decimal.parse()` without try-catch in models — can throw on malformed DB data
- Inventory writes (create/edit product, stock adjust) not write-through to Drift
- `FilteringTextInputFormatter` allows multiple decimal points (e.g. "1.2.3") — `Decimal.tryParse` returns null and validation catches it, but a smarter formatter could reject mid-input
