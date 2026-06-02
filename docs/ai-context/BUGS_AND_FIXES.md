# Bugs and Fixes — Suq ERP

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

## Bug: Stock Correction always fails — "Correction failed. Try again."
Status: Fixed (2026-06-02 session 9)

Cause: `inventory_remote.dart correctStock()` was inserting `'type': 'correction'` into `inventory_adjustments`, but the DB check constraint only allows `('opening_stock','sale','refund','manual','supply_received','void')`. The constraint violation caused `AsyncValue.guard` to catch an error → `state.hasError` → `ok = false`.

Fix: Changed `'type': 'correction'` to `'type': 'manual'` (semantically equivalent — both are admin-override quantity changes).

File: `lib/features/inventory/data/inventory_remote.dart`

---

## Bug: Riverpod accidentally upgraded to 3.x, breaking entire codebase
Status: Fixed (2026-06-02)

Symptoms: 54 analyzer errors — `StateProvider`, `StateNotifierProvider`, `valueOrNull` all undefined.

Cause: `pubspec.yaml` was manually edited (or `flutter pub upgrade --major-versions` was run) between sessions, bumping `flutter_riverpod: ^2.6.1` → `^3.1.0` and several other packages. Riverpod 3.x removed all deprecated 2.x APIs without code migration.

Fix: Restored `pubspec.yaml` to committed versions. Run `flutter pub get`. 0 errors.

Note: Riverpod 3.x migration is a planned task (see OPEN_TASKS.md). Do not run `flutter pub upgrade --major-versions` until the migration is done.

Files: `pubspec.yaml`
