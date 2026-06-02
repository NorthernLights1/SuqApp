# File Map — Suq ERP

All paths relative to `c:/Projects/SuqApp/` (repo root = Flutter project root).

---

## Entry Points

| Path | Purpose | Edit when |
|---|---|---|
| `lib/main.dart` | App entry — Supabase init + ProviderScope + runApp | Rarely |
| `lib/app.dart` | MaterialApp.router — theme, router, l10n | Changing theme, locale, router wiring |
| `pubspec.yaml` | All dependencies — **pinned to Riverpod 2.x / go_router 14.x** | Adding/removing packages; see OPEN_TASKS before upgrading |
| `config/env.json` | Supabase URL + anon key (gitignored) | On project change |
| `config/env.json.example` | Template for env.json | Documenting new env vars |

---

## Core Layer (`lib/core/`)

| Path | Purpose | Edit when |
|---|---|---|
| `core/constants/app_constants.dart` | App name, default locale, currency, sync warning hours | Changing app-wide defaults |
| `core/constants/setting_keys.dart` | All `shop_settings` key names | Adding a new shop setting |
| `core/errors/app_error.dart` | Sealed error hierarchy | Adding a new error type |
| `core/services/permission_service.dart` | Central RBAC — queries `shop_users→roles→permissions` | Changing permission logic |
| `core/services/sync_service.dart` | Offline sync — pushes pending sales to Supabase | Changing sync behavior |

---

## Domain Layer (`lib/domain/`)

| Path | Purpose | Edit when |
|---|---|---|
| `domain/models/product.dart` | `Product`, `CartItem`, `PaymentMethod`, `Customer`, `SaleItem`, `Sale` models | Changing model shape |
| `domain/models/shop.dart` | `Shop`, `Branch` models | Changing shop/branch shape |
| `domain/interfaces/` | Service contracts (`IPermissionService`, `ISyncService`, etc.) | Changing service API |

---

## Local Data Layer (`lib/data/local/`)

| Path | Purpose | Edit when |
|---|---|---|
| `data/local/app_database.dart` | Drift DB schema — tables, type converters, all queries | Adding tables or queries |
| `data/local/database_provider.dart` | `appDatabaseProvider` — returns `AppDatabase?` (null on web) | Changing DB provider behavior |
| `data/local/open_database.dart` | Web stub — throws UnsupportedError | Rarely |
| `data/local/open_database_native.dart` | Native DB opener — `LazyDatabase` pointing to `suq.db` in documents dir | Rarely |
| `data/local/seed_service.dart` | Seeds products/stock/customers from Supabase into Drift on first load | Changing seed logic |

---

## Shared Layer (`lib/shared/`)

| Path | Purpose | Edit when |
|---|---|---|
| `shared/router/app_router.dart` | GoRouter, `_AuthRefreshNotifier`, redirect logic | Adding routes or changing auth redirects |
| `shared/router/app_routes.dart` | Route path constants | Adding a new route |
| `shared/theme/app_colors.dart` | Color tokens | Changing brand colors |
| `shared/theme/app_theme.dart` | Material3 ThemeData | Changing global widget styling |
| `shared/theme/app_text_styles.dart` | Named text styles | Adding/changing typography |
| `shared/widgets/app_text_field.dart` | Reusable form text field — has `inputFormatters` parameter | Changing global input behavior |
| `shared/widgets/app_button.dart` | Primary button with loading state | Changing global button behavior |

---

## Auth Feature (`lib/features/auth/`)

| Path | Purpose | Edit when |
|---|---|---|
| `auth/presentation/providers/auth_provider.dart` | `AuthNotifier`, session providers, `supabaseClientProvider`, `currentUserIdProvider` | Changing auth flow |
| `auth/presentation/providers/shop_provider.dart` | `currentShopProvider`, `currentShopBranchesProvider`, `activeBranchProvider` | Adding shop/branch queries |
| `auth/presentation/screens/login_screen.dart` | Login form | Changing login UI |
| `auth/presentation/screens/signup_screen.dart` | Signup form | Changing signup UI |

---

## Onboarding Feature (`lib/features/onboarding/`)

| Path | Purpose | Edit when |
|---|---|---|
| `onboarding/presentation/providers/onboarding_provider.dart` | `OnboardingNotifier` — creates shop + branch + default settings | Changing onboarding data; default `inventory_mode` is `'"strict"'` here |
| `onboarding/presentation/screens/onboarding_screen.dart` | 4-step onboarding UI | Changing onboarding flow |

---

## Inventory Feature (`lib/features/inventory/`)

| Path | Purpose | Edit when |
|---|---|---|
| `inventory/data/inventory_remote.dart` | All Supabase inventory calls — products, stock levels, `addStock`, `correctStock`, `manualAdjustment`, categories, units | Adding inventory operations |
| `inventory/presentation/providers/inventory_provider.dart` | `productsProvider`, `stockLevelsProvider`, `ProductFormNotifier`, `StockAdjustmentNotifier` (with `addStock`, `correctStock`) | Adding inventory providers |
| `inventory/presentation/screens/inventory_screen.dart` | Unified product+stock list, bottom sheet actions, `_AddStockDialog`, `_CorrectStockDialog`, `ProductFormScreen` | Changing inventory UI |

---

## Sales Feature (`lib/features/sales/`)

| Path | Purpose | Edit when |
|---|---|---|
| `sales/data/sales_remote.dart` | Supabase sales calls — search products/customers, create/void sale, stock enforcement | Changing sale write logic |
| `sales/domain/sales_repository.dart` | Local-first sale logic — Drift pre-check (aggregated per product), fire-and-forget Supabase sync | Changing sale flow |
| `sales/presentation/providers/sales_provider.dart` | All sale providers — cart, search, create, void, `SeedNotifier` | Adding sale state |
| `sales/presentation/screens/` | NewSaleScreen, SalesScreen, SaleDetailScreen | Changing sales UI |

---

## Customers Feature (`lib/features/customers/`)

| Path | Purpose | Edit when |
|---|---|---|
| `customers/presentation/providers/customers_provider.dart` | `customersProvider`, `CustomerFormNotifier` (save, settleDebt, **receivePayment**), `customerSalesProvider` | Adding customer operations |
| `customers/presentation/screens/customers_screen.dart` | Customer list, `CustomerDetailScreen` (with **Receive Payment** dialog), `CustomerFormScreen`, `_ReceivePaymentDialog` | Changing customer UI |

---

## Settings Feature (`lib/features/settings/`)

| Path | Purpose | Edit when |
|---|---|---|
| `settings/presentation/providers/settings_provider.dart` | `BranchNameNotifier` | Adding settings |
| `settings/presentation/screens/settings_screen.dart` | Settings UI — shop info, branch edit | Changing settings UI |

---

## Other Features

| Path | Purpose |
|---|---|
| `features/expenses/` | Record expense, categories, date filter |
| `features/reports/` | Sales summary, gross profit, expense breakdown, low-stock |
| `features/staff/` | Staff list, invite via Edge Function, suspend/restore |
| `features/dashboard/` | Bottom nav shell, home tab, summary cards |

---

## L10n (`lib/l10n/`)

| Path | Purpose |
|---|---|
| `l10n/app_en.arb` | English string keys — edit when adding user-facing text |
| `l10n/app_localizations.dart` | Generated — never edit manually |

Run `flutter gen-l10n` after editing `app_en.arb`.

---

## Supabase Migrations (`supabase/migrations/`)

| File | Domain |
|---|---|
| `001_identity_access.sql` | profiles, shops, branches, roles, permissions, shop_users |
| `002_inventory.sql` | measurement_units, product_categories, products, inventory, inventory_adjustments |
| `003_sales.sql` | payment_methods, customers, sales, sale_items, discounts |
| `004_supplies.sql` | suppliers, supply_orders (stub) |
| `005_financials.sql` | expense_categories, expenses, cash_reconciliations |
| `006_system.sql` | shop_settings, notification tables, export_jobs, sync_logs, handle_new_user trigger |

---

## Tests

| Path | Purpose |
|---|---|
| `test/data/local/app_database_test.dart` | Drift DB unit tests + edge cases (27 tests) |
| `test/domain/models/models_test.dart` | Model parsing tests — CartItem, Sale, Product, Customer, PaymentMethod (30 tests) |
| `test/features/sales/sales_repository_test.dart` | SalesRepository tests — inventory enforcement, totals, DB writes, search (34 tests). Uses `_StubSalesRemote implements SalesRemote` (no mocking library needed). |
