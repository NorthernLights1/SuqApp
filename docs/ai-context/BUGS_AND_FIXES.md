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

Symptoms: Tapping + in Inventory only showed Name, Price, Low Stock Threshold. No category picker, no way to set initial stock quantity or expiry date when creating a product.

Cause (3 parts):
1. `product_categories` table existed in DB and `Product.categoryId` existed, but no provider fetched categories and no picker was in the form.
2. Opening stock lives in `inventory` table (separate from `products`). The form only inserted into `products`. No `setOpeningStock` call was made at creation time.
3. `inventory.expiry_date` was added in migration 008 but never exposed in the creation flow.

Fix:
- Added `ProductCategory` model + `getProductCategories()` + `createProductCategory()` to `InventoryRemote`
- Added `productCategoriesProvider` to `inventory_provider.dart`
- Updated `ProductFormNotifier.save` to accept `initialQuantity` + `expiryDate`; calls `setOpeningStock` atomically after product creation if qty > 0
- Updated `StockAdjustmentNotifier.setOpening` to thread `expiryDate` through
- Added to `ProductFormScreen`: category dropdown with inline "New category" creation, Opening Stock section (new products only), Expiry Date picker (appears when qty > 0)

Files changed: `inventory_remote.dart`, `inventory_provider.dart`, `inventory_screen.dart`

---

## Bug: isExpired / isExpiringSoon used time-sensitive comparison
Status: Fixed (2026-05-29)

Symptoms: Setting expiry date to today immediately marked stock as expired (today at midnight < DateTime.now() at any time of day = true).

Cause: `expiryDate!.isBefore(DateTime.now())` compares against current time, not midnight.

Fix: Both getters now compare against `DateTime(now.year, now.month, now.day)` (date-only):
```dart
bool get isExpired {
  if (expiryDate == null) return false;
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  return expiryDate!.isBefore(today);
}
```
Same pattern applied to `isExpiringSoon`.

Additional: `firstDate` in new product expiry picker changed to tomorrow; `_save()` validates expiry > today as defence-in-depth.

File changed: `inventory_remote.dart`, `inventory_screen.dart`

---

## Bug: `permission denied for table shops` / `shop_users` (42501)
Status: Fixed (2026-05-30)

Symptoms: Onboarding step 1 failed with `PostgrestException code 42501` — first on `shops`, then on `shop_users`.

Cause: Supabase has two independent access layers: (1) PostgreSQL table grants and (2) RLS policies. The migrations created RLS policies but did not include base GRANT statements. PostgREST blocks before RLS even runs if the role has no grant.

Fix: Ran in Supabase SQL Editor:
```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
```

Note: Always check BOTH grants AND RLS when debugging Supabase 42501 errors. Use:
```sql
SELECT table_name, string_agg(privilege_type, ', ') as grants
FROM information_schema.role_table_grants
WHERE grantee = 'authenticated' AND table_schema = 'public'
GROUP BY table_name ORDER BY table_name;
```

---

## Bug: 3 orphaned shops, 0 shop_users records — app broken after failed onboarding
Status: Fixed (2026-05-30)

Symptoms: After multiple failed onboarding attempts, `shops` had 3 rows but `shop_users` had 0. App found the shops (via `owner_id = auth.uid()` RLS) and skipped onboarding, but RLS on `measurement_units`, `product_categories`, and `products` all use `is_shop_member()` which reads `shop_users`. With 0 rows, every inventory query failed.

Cause: Each onboarding attempt created a `shops` row but the `shop_users` INSERT failed (42501 grant issue, now fixed). Each failed attempt left an orphaned shop.

Fix: Ran in Supabase SQL Editor:
```sql
-- Insert missing shop_users record for owner
INSERT INTO public.shop_users (shop_id, user_id, role_id, status)
SELECT '12398dee-c037-4ccf-8d11-a19ebddf581f', u.id,
  '00000000-0000-0000-0000-000000000001', 'active'
FROM auth.users u WHERE u.email = 'temeg242@gmail.com';

-- Delete orphaned shops
DELETE FROM public.shops
WHERE id IN ('cb56a4ee-02a9-40f8-96e4-1d5a5636e033', '07f58715-e866-4bc5-8998-43e2fceda27a');
```

Note: The onboarding flow in `onboarding_provider.dart` is NOT atomic — if the `shop_users` INSERT fails after the `shops` INSERT succeeds, you get orphaned shops. This is low risk now that grants are fixed, but should be wrapped in a Postgres function/transaction if it recurs.

---

## Bug: `selling_price` column missing from `products` table
Status: Fixed (2026-05-30)

Symptoms: `PostgrestException PGRST204 / 42703 — column products.selling_price does not exist`. Reloading schema cache (`NOTIFY pgrst, 'reload schema'`) confirmed the column was never created.

Cause: The migration for `products` table did not include `selling_price`. The app code references it in all SELECT and INSERT queries.

Fix: Ran in Supabase SQL Editor:
```sql
ALTER TABLE public.products ADD COLUMN selling_price numeric;
```

---

## Bug: Stock levels not refreshing in UI after sale
Status: Fixed (2026-05-30)

Symptoms: Sale recorded correctly in DB (inventory_adjustments confirmed), but inventory screen still showed old quantity until app restart.

Cause: `CreateSaleNotifier.submit` invalidated `todaySalesTotalsProvider` but not `stockLevelsProvider`.

Fix: Added to `CreateSaleNotifier.submit` in `sales_provider.dart`:
```dart
ref.invalidate(stockLevelsProvider);
```
Also clears `selectedCustomerProvider` and `customerSearchQueryProvider` after sale.

---

## Bug: ListTile ink splash invisible + RenderFlex overflow in customer picker
Status: Fixed (2026-05-30)

Symptoms: Flutter exception "ListTile background color or ink splashes may be invisible" + 14px right overflow when credit payment selected.

Cause 1: ListTile inside Container(color:) has no Material ancestor for ink. Fix: Wrap ListTile in `Material(type: MaterialType.transparency)`.

Cause 2: `TextButton('+ New')` placed as `suffix` inside `InputDecoration` overflowed. Fix: Moved button outside TextField into a `Row([Expanded(TextField), TextButton])` layout.
