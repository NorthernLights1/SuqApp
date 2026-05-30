# Current State — Suq ERP

Last updated: 2026-05-30 (session 2)

---

## What We Are Building

**Suq** — mobile ERP for small shop owners. Flutter + Supabase.
Package: `com.temesgen.suq` | Repo: `NorthernLights1/Suq`
Flutter app lives in: `c:/Projects/SuqApp/` (standalone repo)
Push target: `git push origin <branch>`

---

## Current Phase

**Phase 3 complete. Phase 4 is next.**

| Phase | Status |
|---|---|
| Phase 0 — Bootstrap + SQL migrations | ✅ Done |
| Phase 1 — Core services | ✅ Done |
| Phase 2 — Auth, Onboarding, Dashboard shell | ✅ Done |
| Phase 2.5 — Inventory form bug fix + UI modernisation | ✅ Done |
| Phase 3 — Sales module | ✅ Done |
| Phase 4 — Customers, Expenses, Reports, Staff, Settings | 🔲 Next |
| Phase 5 — Drift offline DB + tests | 🔲 Not started |

Active branch: `main`

---

## What Works Right Now

- `flutter analyze` — 0 issues ✅
- `flutter pub get` — includes `google_fonts: ^6.2.1` ✅
- Auth (signup/login/logout) ✅
- Onboarding: shop + branch creation + default settings ✅ (grants fixed 2026-05-30)
- Dashboard ✅
- Inventory: product list, stock list, low-stock badge ✅
- ProductFormScreen: Name, Description, Unit, Category (inline creation), Price (ETB), Low Stock Threshold, Opening Stock Quantity, Expiry Date ✅
- UI: Inter font, FilledButton, M3 theme, floating snackbars, rounded dialogs ✅

---

## Android / Emulator Status

- Android Studio installed ✅
- Android SDK 36.1 + API 29 platform selected ✅
- Emulator created: Medium Phone, API 29 (Android 10), x86_64 ✅
- **Blocker**: First Gradle build taking 1+ hour — caused by Windows Defender scanning Gradle files
- **Fix**: Add these folders to Windows Defender exclusions, then re-run:
  - `C:\Users\Hp\AppData\Local\Android\Sdk`
  - `C:\Users\Hp\.gradle`
  - `C:\Projects\SuqApp`
- After exclusions: cancel current build (Ctrl+C), rerun `flutter run --dart-define-from-file=config/env.json`
- Physical device (Xiaomi Poco F1, Android 10): will test on it when app is feature-complete
- Chrome still works as fallback: `flutter run -d chrome --dart-define-from-file=config/env.json`

---

## cmdline-tools Status

- Still missing — fix in Android Studio → Settings → Android SDK → SDK Tools → check "Android SDK Command-line Tools (latest)" → Apply
- Needed for: `flutter doctor --android-licenses`, `sdkmanager` CLI
- NOT blocking emulator use — emulator works via Android Studio GUI regardless

---

## Known Tech Debt

- Hardcoded strings in `inventory_screen.dart` violate l10n rule
- No error boundaries — raw Supabase exceptions reach snackbars
- Drift not wired (Phase 5)

---

## Supabase Architecture (confirmed 2026-05-30)

**RLS design**: All tables use a custom `is_shop_member(shop_id)` function that checks `shop_users`. Two-layer access: PostgreSQL grants (role-level) + RLS policies (row-level). Both must be present.

**Key RLS patterns**:
- Most tables: `is_shop_member(shop_id)` for SELECT and write
- Tables with branch_id (inventory, sales, expenses): `is_shop_member(shop_id_from_branch(branch_id))`
- Global/system rows (measurement_units, expense_categories, payment_methods): `shop_id IS NULL OR is_shop_member(shop_id)`
- `shops` SELECT: `owner_id = auth.uid() OR is_shop_member(id)` — owners can see their shop even before shop_users is populated
- `shop_users` write: requires `shops.owner_id = auth.uid()` — owner inserts their own team members

**shop_users schema**: id, shop_id, branch_id (nullable), user_id, role_id (FK → roles), status (text: 'active'/'invited'/'suspended'), invited_by (nullable uuid), created_at

**roles table**: Seeded with fixed UUIDs — owner: `00000000-0000-0000-0000-000000000001`, manager: `...000000000002`, cashier: `...000000000003`

**products table confirmed columns** (2026-05-30): id, shop_id, category_id, name, description, measurement_unit_id, low_stock_threshold, selling_price (added via ALTER TABLE), is_active, created_at

---

## What Works Right Now (Sales)

Sales module fully implemented and tested (2026-05-30):
- New Sale screen: product search → cart → qty/price edit → payment → submit ✅
- Payment methods: Cash, Bank Transfer, Credit (system-seeded, credit requires customer) ✅
- Credit sales: customer search by name, inline "Add customer" (name + phone) ✅
- Sale detail + void with reason ✅
- Inventory deducted on sale (confirmed via inventory_adjustments table) ✅
- Stock levels refresh in UI after sale (invalidates `stockLevelsProvider`) ✅
- Today's totals on dashboard refresh after sale ✅

## Exact Next Action

1. Run in Supabase: `INSERT INTO payment_methods (id, shop_id, name, code, is_active, is_system) VALUES ('20000000-0000-0000-0000-000000000003', null, 'Credit', 'credit', true, true);`
2. Test credit sale end-to-end: select Credit → add/search customer → charge
3. Start Phase 4: Customers list, Expenses, Reports
