# Bugs and Fixes — Suq ERP

---

## Session 20 (2026-06-19) — action feedback (branch `feat/action-feedback`)

**Pre-existing bug — Credit settle sheet closed on failure.**
`_SettleSheetState._confirm()` called `Navigator.pop(context)` unconditionally before the
`if (!ok)` check — sheet always closed even when payment recording failed, giving user no
chance to retry. Fix: restructured into `if (ok) { snackbar + pop } else { error snackbar }`.
`credits_screen.dart`.

**Pre-existing silent failure — Product deactivation showed nothing on error.**
`_ProductFormScreenState._deactivate()` only called `Navigator.pop` on success; failure path
was empty — user had no idea the removal failed. Fix: added error snackbar on failure.
`inventory_screen.dart`.

**Missing success feedback on 4 write operations.**
- Expenses: "Expense recorded" green snackbar before pop (`expenses_screen.dart`).
- Add Stock: "Stock added" green snackbar before pop (`inventory_screen.dart`).
- Correct Stock: "Stock corrected" green snackbar before pop (`inventory_screen.dart`).
- Product save: context-aware "Product updated" / "Product added" snackbar + error with
  provider error message (`inventory_screen.dart`).

---

## Session 19 (2026-06-17) — offline-first device testing (branch `offline-first_v2`)

**Bug 7 — Today report zeros after sync (UTC timestamp mismatch). FIXED (commit `d05ee82`).**
`sync_service.dart` was calling `.toIso8601String()` on local DateTimes without `.toUtc()`.
Postgres `timestamptz` treated the bare string as UTC → stored 3h wrong (EAT UTC+3) →
delta pull brought back wrong epoch millis → today-range query excluded the sale → zeros.
Fix: `.toUtc()` before all `.toIso8601String()` calls in `_saleJson`, `_pushPendingExpenses`,
`_writeSyncLog`. Also reverted a no-op `.toUtc()` on Drift epoch-millis queries in
`reports_provider.dart` (commit `f032fae`) — Drift stores INTEGER epoch ms, so `.toUtc()`
on query parameters changes nothing.

**Bug 11 — Reports only show post-update sales. NOT A BUG.**
Pre-update sales were voided during testing. Reports correctly exclude voided sales
(`status == 'completed'` filter everywhere). Confirmed: voided sales appear in the
sales list (operational log) and are correctly excluded from revenue totals.

**Bug 6 — Add Stock with changed price/threshold fails offline. ALREADY FIXED (prior CodeRabbit round).**
Inventory screen already shows a snackbar on product-update failure but does NOT return —
stock adjustment proceeds regardless. Code at `inventory_screen.dart:401` with comment
"Still proceed to queue the stock adjustment — it is offline-safe and independent."

**Bug 1 — Void sale offline shows raw SocketException. FIXED (commit `9a55b7f`).**
`sales_repository.dart:voidSale` now catches network/timeout exceptions and rethrows with
"Voiding a sale requires an internet connection." Real server rejections propagate as-is.

**Bug 4 — New product category fails offline. FIXED (commit `9a55b7f`).**
`inventory_repository.dart:createProductCategory` now writes locally first with
`isSynced=false` (client-generated UUID) and returns immediately. SyncService pushes in
background. Web path still goes remote-only.

**Bug 5 — New product creation fails offline. FIXED (commit `9a55b7f`).**
`inventory_repository.dart:createProduct` now writes locally first with `isSynced=false`.
Looks up `measurementUnitAbbr` from local unit cache. SyncService pushes categories before
products (FK order). Web path still goes remote-only.

**Bugs 10+12 — Reports slow + expenses delayed. FIXED (commit `9a55b7f`).**
`reportSummaryProvider` and `reportSalesProvider` were remote-first; network wait caused
slowness (Bug 10) and unsynced expenses weren't visible (Bug 12) because the remote read
returned data from Supabase before the local expense was pushed. Both providers flipped to
local-first on native — instant read from Drift mirror, no network on the critical path.
Web retains remote-only path.

**Schema: v10 → v11 (commit `9a55b7f`).**
`LocalProductCategories` and `LocalProducts` gained `isSynced bool default(true)`.
`watchHasPendingWork()` updated to arm the sync nudge on new offline product/category
writes. Migration: `if (from < 11)` addColumn products; `if (from >= 5 && from < 11)`
addColumn categories (v1–v4 DBs get it from the v5 createTable step).

**Bug 8 — Login fails when offline (raw auth exception). FIXED (commit `16e5bb5`).**
Two parts. (1) Message: new top-level `friendlyAuthError(Object)` in
`auth_provider.dart` classifies the failure — offline (`AuthRetryableFetchException`
or raw socket/client errors) → "No internet connection. You need to be online the
first time you sign in…"; 400 / "invalid login credentials" → "Incorrect email or
password."; 429 / rate → "Too many attempts — wait a minute…". `login_screen.dart`
now renders that instead of `authState.error.toString()`. (2) Cached session usable
offline: `supabase_flutter` already restores the session from local storage on cold
start (no network), but the router's owner/staff lookup then waited up to 5s before
reaching the dashboard. `app_router.dart` now does a `Connectivity().checkConnectivity()`
check first — if offline with a restored session it routes straight to the dashboard
(same destination as the old timeout fallback, but instant). Note: a *first-ever*
login still requires internet by design (no password stored on device). 5 unit tests
for the classifier in `test/features/auth/friendly_auth_error_test.dart`.

**Bug 9 — Wrong password shows raw exception. FIXED (commit `16e5bb5`, same classifier).**
Folded into Bug 8: `friendlyAuthError` maps the 400 / "invalid login credentials"
case to "Incorrect email or password." — the login screen was the one remaining
sign-in path still dumping the raw `AuthException` (inventory + accept-invite already
used `on AuthException catch`).

**Code cleanups (commit `a97380d`):**
Five trivial improvements from CodeRabbit feedback review: (1) removed 4× redundant
`try/catch` blocks in `sync_service.dart` that only rethrow (−20 lines); (2) fixed
misleading "always seeded" comment in `inventory_repository.dart` (seeding can fail);
(3) eliminated double-trim of description field (stored trimmed result in variable);
(4) simplified offline-check logic in `app_router.dart` (`!any(...!= none)` → `every(...== none)`);
(5) added test case for unknown AuthException to complete classifier coverage.

---

## Session 17 (2026-06-12) — test-feedback batch (12 items, all on `main`)

**Manager/credit-detail saw only own-device sales (root cause for 3 reports).**
`SalesRepository.getSalesForBranch`/`getSale` read local-Drift-first; the local
mirror holds only sales made on that device and lacks join data. Fix: server-first
reads (fall back to local only when offline). Added cashier join
(`profiles!sales_cashier_id_fkey`) → `Sale.cashierName` ("Sold by").

**Offline → black screen on cold start.** Router redirect awaited Supabase
lookups with no timeout; offline they hung with no UI. Fix: `.timeout(5s)` on the
shop/membership lookups → caught → logged-in user falls through to dashboard.

**New inventory item needed app restart.** Add-product is a pushed route
(`ProductFormScreen`); its in-form invalidation wasn't reflected on the list. Fix:
FAB awaits the push and invalidates products/stock on return.

**Reports accessible to cashiers.** `PermissionService` existed but was wired to
nothing. Fix: new `permissionsProvider`; Reports entry points hidden + screen
guarded for users without `reports.view`.

**"Send overdue reminders" looked broken.** Function returns HTTP 200 even when
nothing is overdue; app treated any 200 as "sent". Diagnosed live: 1 unpaid
credit, 0 past the 7-day window. Fix: `dispatch()` returns `DispatchResult`
(sent+reason); Settings shows "No credits are overdue yet". Also fn v5 now emails
ALL `notification_email` rows (was last-one-wins).

**Voided credit lingered in customer credit view.** `voidSale` invalidated the
Credits tab but not the per-customer families. Fix: also invalidate
`customerCreditSalesProvider` / `customerSalesProvider` / `customerOutstandingMapProvider`.

**Other:** voided sale no longer decrements the transaction count (revenue still
excludes it); reports category filter → combo box; new tappable Transactions/Credits
drill-downs (date+category filter); payment history on sale detail.

---

## Session 16 (2026-06-09)

**ROOT CAUSE — staff invites & notifications all 403'd: `service_role` lost table grants.**
A blanket REVOKE had stripped `SELECT/INSERT/UPDATE/DELETE` from `service_role` on all 32
public tables. Hidden until the project moved to new API keys (`sb_secret`), which made
Edge Functions actually authenticate as `service_role` → every admin query "permission
denied for table ..." → owner-check returned nothing → 403. Fix: migration 013 re-grants
service_role full DML + default privileges (server-only role, RLS unaffected). Diagnosed
via a temp `test-email` function running the exact owner-check query (got 42501).

**Staff-invite UI reported false success.** `InviteStaffNotifier.invite` wrapped the call
in `AsyncValue.guard` and returned without rethrowing → 403s showed the green "Invite email
sent" snackbar. Fix: await `invoke()` directly, extract `FunctionException.details['error']`,
rethrow (commit 1336761).

**Times shown 3h off (UTC).** `Sale.fromJson`/`CreditSale` parsed UTC timestamps without
`.toLocal()`. Fix: `.toLocal()` in fromJson (c9b8cb7).

**Sales/reports filtered wrong near day boundary.** `salesListProvider` etc. built the
"today" range as local DateTime and serialized with `toIso8601String()` (no offset) → Postgres
read it as UTC. Fix: `.toUtc().toIso8601String()` in remote date-range queries (8487b87).

**Sales list one-behind.** submit() invalidated `salesListProvider` but returned before the
refetch. Fix: `await ref.read(salesListProvider.future)` after invalidating (2241b8e).

**Multi-item sale could half-deduct stock.** `SalesRemote.createSale` inserted then validated
per-item, rolling back via delete. Fix: validate the whole cart's stock BEFORE any write (c9b8cb7).

**Low-stock email never arrived (per-sale model).** Function 400'd: no `notification_email`
configured. Resolved by the scheduled model using owner email as default recipient.

**Staff "invited" never flipped to "active".** Router updated shop_users as the staff member,
but `shop_users_write` is owner-only → silent fail. Fix: `activate_my_membership()` SECURITY
DEFINER RPC (migration 015, commit 72f2f22).

**Staff names showed "Unknown".** `profiles_select` RLS was `auth.uid()=id` only. Fix:
`private.shares_shop_with()` + widened policy (migration 014, commit 8c77f42). Chose this over
denormalizing name onto shop_users (which is owner-write-only).

**Stray conda GitHub Action emailing failures.** Deleted `python-package-conda.yml` template
from `feat/phase-0-bootstrap`.

---

## Bug: Signup fails with 500 "Database error saving new user"
Status: Fixed

Cause: `handle_new_user()` trigger missing `set search_path = public`.
Fix: Recreated function with `set search_path = public` in Supabase SQL Editor.
Note: Always add `set search_path = public` to any `security definer` function in Supabase.

---

## Bug: Login succeeds but app stays on login screen
Status: Fixed

Cause: `GoRouter` instantiated inside `build()` — new instance on every rebuild, auth notifier fired on old instance.
Fix: Converted `SuqApp` to `ConsumerStatefulWidget`, router cached as `late final` in state.
Note: Never instantiate `GoRouter` inside a `build()` method.

---

## Bug: `app_routes.dart` part-of import error
Status: Fixed

Cause: `app_routes.dart` had `part of 'app_router.dart'` but was also imported directly as a library.
Fix: Removed `part of` directive, made it standalone.

---

## Bug: ProductFormScreen missing Category, Opening Stock, Expiry Date fields
Status: Fixed (2026-05-29)

Symptoms: Tapping + in Inventory only showed Name, Price, Low Stock Threshold.

Cause (3 parts):
1. No provider fetched categories, no picker in form.
2. Opening stock lives in `inventory` table — form only wrote to `products`.
3. `inventory.expiry_date` never exposed in creation flow.

Fix: Added `ProductCategory` model + remote methods; `ProductFormNotifier.save` calls `setOpeningStock` after creation if qty > 0; added category dropdown, Opening Stock section, Expiry Date picker to form.

Files: `inventory_remote.dart`, `inventory_provider.dart`, `inventory_screen.dart`

---

## Bug: isExpired / isExpiringSoon used time-sensitive comparison
Status: Fixed (2026-05-29)

Cause: `expiryDate!.isBefore(DateTime.now())` compared against current time, not midnight.
Fix: Both getters compare against `DateTime(now.year, now.month, now.day)`.
Also: expiry picker `firstDate` set to tomorrow; `_save()` validates expiry > today.

File: `inventory_remote.dart`, `inventory_screen.dart`

---

## Bug: `permission denied for table shops` / `shop_users` (42501)
Status: Fixed (2026-05-30)

Cause: Migrations created RLS policies but no base GRANT statements. PostgREST blocks before RLS if role has no grant.
Fix:
```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
```
Note: Always check BOTH grants AND RLS when debugging 42501. Check grants with `information_schema.role_table_grants`.

---

## Bug: 3 orphaned shops, 0 shop_users records
Status: Fixed (2026-05-30)

Cause: Each failed onboarding attempt created a `shops` row but `shop_users` INSERT failed (grants issue). Orphaned shops caused RLS failures on all inventory queries.
Fix: Manual SQL — inserted missing `shop_users` record, deleted 2 orphaned shops.
Note: Onboarding is NOT atomic — `shops` INSERT can succeed while `shop_users` fails.

---

## Bug: `selling_price` column missing from `products` table
Status: Fixed (2026-05-30)

Cause: Migration never included the column.
Fix: `ALTER TABLE public.products ADD COLUMN selling_price numeric;`

---

## Bug: Stock levels not refreshing in UI after sale
Status: Fixed (2026-05-30)

Cause: `CreateSaleNotifier.submit` did not invalidate `stockLevelsProvider`.
Fix: Added `ref.invalidate(stockLevelsProvider)` to `CreateSaleNotifier.submit`.

---

## Bug: ListTile ink splash invisible + RenderFlex overflow in customer picker
Status: Fixed (2026-05-30)

Cause 1: ListTile inside `Container(color:)` has no Material ancestor for ink.
Fix 1: Wrap in `Material(type: MaterialType.transparency)`.

Cause 2: `TextButton('+ New')` as `suffix` in `InputDecoration` overflowed.
Fix 2: Moved button outside TextField into `Row([Expanded(TextField), TextButton])`.

---

## Bug: Product search broken on web (Chrome) after Phase 5
Status: Fixed (2026-06-02)

Symptoms: Product search returned empty results on Chrome; `salesRepositoryProvider` threw `UnsupportedError`.

Cause: `appDatabaseProvider` called `openDatabase()` on web which throws `UnsupportedError('Drift is not supported on this platform')`. This cascaded through `salesRepositoryProvider` → error state → empty search results.

Fix:
- `appDatabaseProvider` returns `AppDatabase?` — `null` on web via `if (kIsWeb) return null`
- `SalesRepository._db` typed as `AppDatabase?`; all DB calls null-guarded
- `createSale` has early-return path for `_db == null` (direct Supabase)
- `_db?.markSaleVoided` for optional update in `voidSale`
- `SyncService._pushSale` refactored to accept `AppDatabase db` parameter (avoids unnecessary `!`)
- `SeedNotifier.build()` early-returns if db is null

Files: `database_provider.dart`, `sales_repository.dart`, `sync_service.dart`, `sales_provider.dart`

---

## Bug: Sales allowed on negative stock / untracked products
Status: Fixed (2026-06-02)

Symptoms: Sales could be completed even when stock would go negative, and when products had no inventory record.

Cause: Default `inventory_mode` was `'flexible'`, which bypassed all stock checks. Even in strict mode, `stock == null` was treated as `flagged` (sale allowed) rather than blocked.

Fix (3 iterations, final logic):
- No stock record → block ("X is not in inventory. Add stock before selling.")
- Stock record present, stock < quantity → block ("Not enough stock for X. Available: N")
- Stock record present, stock ≥ quantity → allow, deduct
- Removed `inventoryMode` condition from both `SalesRemote` and `SalesRepository` checks — enforcement is unconditional
- Changed `stock == null → flagged` to `stock == null → block` in both paths
- Changed onboarding default from `'"flexible"'` to `'"strict"'`
- Updated existing shop in Supabase: `UPDATE shop_settings SET value = '"strict"' WHERE key = 'inventory_mode'`

Files: `sales_remote.dart`, `sales_repository.dart`, `onboarding_provider.dart`

---

## Bug: Same product in multiple cart items could produce negative stock (unit test found)
Status: Fixed (2026-06-02)

Symptoms: If the same product appeared as two separate cart lines (e.g. qty=5 + qty=5 against stock=8), each line passed the per-item pre-check independently (5 ≤ 8, 5 ≤ 8). The deduction loop then re-read the post-first-deduction value and wrote stock to -2.

Cause: `SalesRepository.createSale` pre-check iterated items individually without aggregating quantities per product.

Fix: Pre-check now aggregates total required qty per `productId` using a `Map<String, Decimal>`, then checks each product's combined total against stock once. Deduction loop unchanged (correct: re-reads after each deduction).

File: `lib/features/sales/domain/sales_repository.dart` (pre-check block)

---

## Bug: Stock Correction password always shows "Incorrect password" even with correct credentials
Status: Fixed (2026-06-02)

Symptoms: Owner enters their login password in the Correct Stock dialog; dialog shows "Incorrect password" or "Password verification failed. Check your connection."

Causes:
1. `on AuthException {` (no `catch (e)`) — exception message was unreachable; Supabase rate-limit errors (429) and other AuthException subtypes were all displayed as "Incorrect password"
2. `_pwCtrl.text` missing `.trim()` — trailing whitespace from the virtual keyboard causes `signInWithPassword` to fail

Fix:
- Changed to `on AuthException catch (e)` and inspect `e.statusCode` / `e.message`
- Rate-limit detected (statusCode 429 or message contains "rate"/"after") → shows "Too many attempts — wait a minute then try again"
- Other AuthException → shows "Incorrect password"
- Generic exceptions now show the actual error text
- Added `.trim()` to password value before passing to `signInWithPassword`

File: `inventory_screen.dart` (`_CorrectStockDialogState._submit`)

---

## Bug: Numeric text fields accepted non-numeric characters
Status: Fixed (2026-06-02)

Symptoms: On web (Chrome) and some Android keyboards, qty/price/amount fields accepted letters, symbols, etc. `keyboardType: numberWithOptions` only controls the soft keyboard; it does not filter input.

Fix: Added `FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))` to every numeric field:
- `AppTextField` — new `inputFormatters` parameter wired through to `TextFormField`
- Inventory screen: Add Stock qty, Correct Stock qty, ProductFormScreen (selling price, cost price, threshold, opening qty)
- New Sale screen: qty and price inline fields
- Expenses screen: amount field

Files: `app_text_field.dart`, `inventory_screen.dart`, `new_sale_screen.dart`, `expenses_screen.dart`

---

## Bug: `app_database_test.dart` compilation error — `isNull` ambiguous
Status: Fixed (2026-06-02)

Cause: New edge-case tests used `isNull` matcher; both `drift` and `matcher` export it. The existing `hide isNotNull` on the drift import was not hiding `isNull`.

Fix: `import 'package:drift/dart.dart' hide isNotNull, isNull;`

File: `test/data/local/app_database_test.dart`

---

## Bug: Credit customer name search broken in New Sale screen
Status: Fixed (2026-06-02)

Symptoms: When "Credit" payment method selected, typing in customer search field returned no results.

Cause: `_CustomerPickerSectionState.build` conditionally shows `_CustomerResults` only when `_searchCtrl.text.length >= 2`. But `onChanged` never called `setState`, so the parent widget never rebuilt after typing. The text-length condition was evaluated only once (at mount, when text = ''), so `_CustomerResults` was never shown.

Fix: Added `setState(() {})` at the top of the `onChanged` callback, triggering a rebuild on each keystroke so the condition re-evaluates correctly.

File: `lib/features/sales/presentation/screens/new_sale_screen.dart` (`_CustomerPickerSectionState`)

---

## Bug: No way to partially settle customer credit
Status: Fixed (2026-06-02)

Symptoms: "Mark Settled" button on CustomerDetailScreen zeroed the entire balance. No way to record a partial payment.

Fix:
- Replaced "Mark Settled" button with "Receive Payment" button
- Opens a dialog pre-filled with the full outstanding balance
- Owner can enter any amount: ≥ balance → zeros out (full settlement); < balance → reduces by entered amount
- Added `CustomerFormNotifier.receivePayment(customerId, amount)` — fetches current balance, computes new balance, updates DB
- `ref.invalidate(customersProvider)` on success refreshes the list

Files: `customers_screen.dart`, `customers_provider.dart`

---

## Bug: Stock Correction (and second Add Stock) always fails — 409 Conflict
Status: Fixed (2026-06-03 session 10)

Cause: All four inventory upserts (`setOpeningStock`, `manualAdjustment`, `addStock`, `correctStock`) called `.upsert({...})` WITHOUT `onConflict`. PostgREST defaults to conflict-detection on the PRIMARY KEY (`id`). Since `id` is never included in the payload, no PK conflict is found and PostgREST issues a plain INSERT. The INSERT then hits the `unique(branch_id, product_id)` constraint and returns HTTP 409, which `AsyncValue.guard` catches → `state.hasError` → `ok = false`.

`setOpeningStock` only runs when no row exists yet (first stock entry) so it happened to work. `correctStock` ALWAYS fails because you can only correct stock for a product that is already in inventory (button only shown when `entry != null`). `addStock` would also fail on any re-stock call.

Root cause confirmed via Supabase postgres logs: `duplicate key value violates unique constraint "inventory_branch_id_product_id_key"` and API logs: `POST /rest/v1/inventory → 409`.

Session 9 fix (`'correction'` → `'manual'`) was a red herring — changed which error fired first, but the 409 was always the real killer.

Fix: Added `onConflict: 'branch_id,product_id'` to all four `.upsert()` calls in `inventory_remote.dart`.

Regression tests: `test/features/inventory/inventory_correction_test.dart` — 15 tests (DB layer + enforcement after correction).

File: `lib/features/inventory/data/inventory_remote.dart`

---

## Bug: Riverpod accidentally upgraded to 3.x, breaking entire codebase
Status: Fixed (2026-06-02)

Symptoms: 54 analyzer errors — `StateProvider`, `StateNotifierProvider`, `valueOrNull` all undefined.

Cause: `pubspec.yaml` was manually edited (or `flutter pub upgrade --major-versions` was run) between sessions, bumping `flutter_riverpod: ^2.6.1` → `^3.1.0` and several other packages. Riverpod 3.x removed all deprecated 2.x APIs without code migration.

Fix: Restored `pubspec.yaml` to committed versions. Run `flutter pub get`. 0 errors.

Note: Riverpod 3.x migration is a planned task (see OPEN_TASKS.md). Do not run `flutter pub upgrade --major-versions` until the migration is done.

Files: `pubspec.yaml`

---

## Bug: Sales tab and Credits tab stale after new sale (no refresh without restart)
Status: Fixed (2026-06-06)

Cause: `CreateSaleNotifier.submit` only invalidated `todaySalesTotalsProvider` and `stockLevelsProvider`. `salesListProvider` and `outstandingCreditProvider` were never invalidated, so the lists only updated on next cold load.

Fix: Added `ref.invalidate(salesListProvider)` (always) and `ref.invalidate(outstandingCreditProvider)` (when `isCredit == true`) inside `CreateSaleNotifier.submit`.

File: `lib/features/sales/presentation/providers/sales_provider.dart`

---

## Bug: ListTile ink splash invisible in NewSaleScreen (product search + customer results)
Status: Fixed (2026-06-06)

Cause: `ListTile` inside `Container(BoxDecoration(color: Colors.white))` has no Material ancestor for ink effects — the DecoratedBox sits between ListTile and its nearest Material, making splash invisible.

Fix: Wrapped both `ListTile` instances in `Material(type: MaterialType.transparency)`.
- Product search dropdown: `itemBuilder` in `_ProductSearchSection`
- Customer results: `_CustomerResults` `map()` entries

File: `lib/features/sales/presentation/screens/new_sale_screen.dart`

---

## Bug: RenderFlex overflow 13px in cart item row
Status: Fixed (2026-06-06)

Cause: Line total text wrapped in `SizedBox(width: 72)` — too narrow for 6+ digit amounts (e.g. "1234.50").

Fix: Replaced `SizedBox(width: 72)` with `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))`.

File: `lib/features/sales/presentation/screens/new_sale_screen.dart` (cart item row)

---

## Bug: Staff invite always returns 403 (owner check fails)
Status: Fixed (2026-06-06)

Cause: Edge Function v3 verified ownership with:
`admin.from('shops').select('id').eq('id', shopId).eq('owner_id', caller.id)`
Despite the DB data matching, the admin client query returned null on every call (root cause unclear — possibly a Supabase Edge Function runtime issue with the admin client in this context).

Fix (v4): Replaced the `shops` check with a `shop_users` check using the fixed owner role UUID:
`admin.from('shop_users').select('id').eq('shop_id', shopId).eq('user_id', caller.id).eq('role_id', OWNER_ROLE_ID).eq('status', 'active')`
This is also more robust — works even if `shops.owner_id` is ever out of sync.

Note: Always use `shop_users + role_id` to verify ownership in Edge Functions, not `shops.owner_id`.

File: Supabase Edge Function `invite-staff` (v4 deployed)

---

## Bug: Staff invite accepts duplicate email with no error
Status: Fixed (2026-06-06)

Cause: Edge Function called `inviteUserByEmail` without checking if the email was already registered. For already-registered users, Supabase could return an opaque error or silently resend.

Fix (v4): Before calling `inviteUserByEmail`, call `admin.auth.admin.listUsers()` and search for the email. Three cases:
- Email exists + already in this shop → return 400 with clear message ("already a member" / "already has a pending invite")
- Email exists + not in this shop → insert `shop_users` directly with `status: 'active'` (no invite needed, they can log in), return `{ existing: true }`
- Email not found → send invite normally, return `{ existing: false }`

Flutter UI: `invite()` now returns `bool isExisting`. Success snackbar shows "Invite email sent to X" or "X already has an account — added to your shop directly" accordingly.

Files: Supabase Edge Function `invite-staff` (v4), `staff_provider.dart`, `staff_screen.dart`
---

## Bug: settings upsert inserting duplicates instead of updating (branch_id NULL)

Status: Fixed (session 14, CodeRabbit)

Cause: shop_settings unique constraint is (shop_id, branch_id, key). PostgreSQL treats NULL != NULL in unique indexes, so omitting branch_id from the upsert body meant ON CONFLICT never triggered — rows were inserted rather than updated.
Fix: Explicitly include 'branch_id': null in every shop_settings upsert call.
File: lib/features/settings/presentation/providers/settings_provider.dart

---

## Bugs: 9 code-review findings fixed (session 15)

Status: All fixed (2026-06-06)

**HIGH**
1. Non-atomic sequential upserts — email and overdue_days rows were sent in a for-loop; a network drop after the first commit left settings half-written. Fix: replaced loop with single `upsert(list)` call.
2. Migration 012 CHECK constraint silently skipped — `ADD COLUMN IF NOT EXISTS` no-ops the entire clause (including inline CHECK) when column already exists. Fix: moved constraint to a separate idempotent `DO $$ ADD CONSTRAINT IF NOT EXISTS $$` block.
3. Early-return false-success snackbar — `save()` and `send()` returned early (shop/userId == null) before setting state, leaving it as AsyncData → UI showed "saved" when nothing happened. Fix: moved all guards inside `AsyncValue.guard` so they throw → AsyncError.
4. Unsafe `response.data as Map` cast — Edge Function error with plain-text body threw TypeError instead of the intended message. Fix: `data is Map<String, dynamic>` type check before indexing.

**MEDIUM**
5. Direct `client.functions.invoke` in feature providers bypassed `INotificationService` interface (CLAUDE.md rule #2). Added `dispatch()` method to interface + implementation; registered `notificationServiceProvider` in auth_provider.dart; both callers updated. Also added `NotificationType.overdueCredits` to the enum.
6. Telegram channel seeded as `is_active=true` in migration 012 with no supporting code. Changed to `false`; `ON CONFLICT DO UPDATE` ensures correction on re-run.
7. `_NotificationsCard` `late final` controllers never updated when `notificationSettingsProvider` reloads after save. Fix: added `didUpdateWidget` override.
8. Email regex missing `$` anchor — `hasMatch` accepted strings like `foo@bar.com extra`. Fix: `r'^[^@\s]+@[^@\s]+\.[^@\s]+$'`.

**LOW**
9. Raw `${state.error}` interpolated in user-facing snackbar for reminder send failures. Replaced with generic message.

Files: `settings_provider.dart`, `settings_screen.dart`, `sales_provider.dart`, `auth_provider.dart`, `notification_service.dart`, `notification_service_interface.dart`, `012_notifications.sql`

---
*Related: [[INDEX]] · [[CURRENT_STATE]] · [[OPEN_TASKS]] · [[DECISIONS]] · [[FILE_MAP]]*
