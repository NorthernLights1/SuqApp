# File Map — Suq ERP

All paths relative to `c:/Projects/SuqApp/` (repo root = Flutter project root).

---

## Entry Points

| Path | Purpose | Edit when |
|---|---|---|
| `lib/main.dart` | App entry — Supabase init + ProviderScope + runApp | Rarely |
| `lib/app.dart` | MaterialApp.router — theme, router, l10n | Changing theme, locale, router wiring |
| `pubspec.yaml` | All dependencies — Riverpod 3.x, go_router 17.x | Adding/removing packages |
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
| `core/services/sync_service.dart` | Offline sync — bulk-upserts all pending entities (customers→sales→expenses→credit payments→products→categories) in FK order | Changing sync behavior |

---

## Domain Layer (`lib/domain/`)

| Path | Purpose | Edit when |
|---|---|---|
| `domain/models/sale.dart` | `Sale` (with `customerName`, `customerPhone`, `paymentMethodName`, `creditSettlementMethod`, `creditSettlementNotes`), `SaleItem`, `CartItem`, `PaymentMethod`, `Customer` | Changing sale model shape |
| `domain/models/shop.dart` | `Shop`, `Branch` models | Changing shop/branch shape |
| `domain/interfaces/` | Service contracts (`IPermissionService`, `ISyncService`, etc.) | Changing service API |

---

## Local Data Layer (`lib/data/local/`)

| Path | Purpose | Edit when |
|---|---|---|
| `data/local/app_database.dart` | Drift DB schema (**v19**) — tables, type converters, all queries. Refund tables (v17) + perf indexes (v18) + `batch_adjustments.refundId` link (v19) + `pendingPushCount`/`refundedQtyBySaleItem`/`getRefundTotalByBranchRange`/`getRefundRestockAdjustments` | Adding tables or queries |
| `data/local/database_provider.dart` | `appDatabaseProvider` — returns `AppDatabase?` (null on web) | Changing DB provider behavior |
| `data/local/open_database.dart` | Web stub — throws UnsupportedError | Rarely |
| `data/local/open_database_native.dart` | Native DB opener — `LazyDatabase` pointing to `suq.db` in documents dir | Rarely |
| `data/local/seed_service.dart` | Delta pull engine — per-table cursor (`LocalSyncState`), fetches `updated_at >= cursor`, upserts live rows, hard-deletes soft-deleted rows. First pull is full. 13 `_seedX` registry methods. | Changing pull/sync logic |

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
| `inventory/data/inventory_remote.dart` | Supabase inventory calls — products, stock, `addStock`, `correctStock`, `manualAdjustment`, categories, units, `insertBatch`, `insertBatchAdjustment`, web `getProductBatches` (remaining from depletion+adjustment ledgers); `ProductBatchView` (incl. `received`, `receivedAt`, `addedByName`) | Adding inventory operations |
| `inventory/domain/batch_allocation.dart` | Pure FEFO allocator (`allocateFefo`, `BatchAvailability`, `FefoResult`) — soonest-expiry-first, nulls last, oversell-to-last-lot | Changing FEFO depletion logic |
| `inventory/presentation/providers/inventory_provider.dart` | `productsProvider`, `stockLevelsProvider`, `productBatchesProvider` (family), `ProductFormNotifier`, `StockAdjustmentNotifier` (`addStock`, `correctStock`, `addStockBatch`, `discardBatch`, `correctBatch`) | Adding inventory providers |
| `inventory/presentation/screens/inventory_screen.dart` | Unified product+stock list, bottom sheet actions (incl. wholesale BATCHES section + "Batch details"), `_AddStockDialog`, `_CorrectStockDialog`, `ProductFormScreen` (wholesale batch# field) | Changing inventory UI |
| `inventory/presentation/screens/product_batch_detail_screen.dart` | Wholesale per-lot Details page: card per batch (number/expiry/remaining/received/added-on/added-by) + per-lot **Correct** dialog + **Add batch** dialog | Per-lot detail/correction UI |

---

## Sales Feature (`lib/features/sales/`)

| Path | Purpose | Edit when |
|---|---|---|
| `sales/data/sales_remote.dart` | Supabase sales calls — search products/customers, create/void sale, stock enforcement | Changing sale write logic |
| `sales/domain/sales_repository.dart` | Local-first sale logic — Drift pre-check (aggregated per product), fire-and-forget Supabase sync | Changing sale flow |
| `sales/presentation/providers/sales_provider.dart` | All sale providers — cart, search, create, void, `SeedNotifier` | Adding sale state |
| `sales/presentation/screens/` | NewSaleScreen, SalesScreen, **SaleDetailScreen** (tx ref, customer card, settlement notes card, credit status banner) | Changing sales UI |

---

## Customers Feature (`lib/features/customers/`)

| Path | Purpose | Edit when |
|---|---|---|
| `customers/presentation/providers/customers_provider.dart` | `customersProvider`, `CustomerFormNotifier` (save, settleDebt, **receivePayment**, **settleCreditSale**), `outstandingCreditProvider`, `CreditSaleWithCustomer` model | Adding customer operations |
| `customers/presentation/screens/customers_screen.dart` | Customer list, `CustomerDetailScreen` (with **Receive Payment** dialog), `CustomerFormScreen` | Changing customer UI |
| `customers/presentation/screens/credits_screen.dart` | **Credits tab** — unsettled bills grouped by customer, per-bill settle sheet (Cash/Bank Transfer), `showCreditSettleSheet()` public helper | Changing credit reconciliation UI |

---

## Settings Feature (`lib/features/settings/`)

| Path | Purpose | Edit when |
|---|---|---|
| `settings/presentation/providers/settings_provider.dart` | `BranchNameNotifier` | Adding settings |
| `settings/presentation/providers/shop_type_provider.dart` | `shopTypeProvider` (retail/wholesale, local-cache fallback) + `AsyncValue<String>.isWholesale` gate | Gating wholesale-only features |
| `settings/presentation/screens/settings_screen.dart` | Settings UI — shop info, branch edit | Changing settings UI |

---

## Other Features

| Path | Purpose |
|---|---|
| `features/expenses/` | Record expense, categories, date filter |
| `features/reports/` | **Card hub** (`reports_screen.dart`) → dedicated `report_sales_screen` / `report_inventory_screen` / `report_expenses_screen` / `report_revenue_screen`; shared `widgets/report_filters.dart` (period/category/stat). `reports_provider.dart` `ReportSummary` now carries `refundTotal` (nets revenue) |
| `features/refunds/` | Offline-first refunds. `domain/refund_restock.dart` (pure `allocateRestock` FEFO-reverse + `proportionalRefund`), `domain/refunds_repository.dart` (local-first create, optimistic stock, over-refund guard), `data/refunds_remote.dart` (web path). **Both web + native-sync push via the `upsert_refund_with_inventory` RPC (atomic refund+items+restock).** `presentation/providers/refunds_provider.dart` (`createRefundProvider`, `refundedQtyProvider`), `presentation/screens/refund_screen.dart` (partial picker). Entry: Refund action on SaleDetailScreen |
| `features/staff/` | Staff list, invite via Edge Function (OTP code flow), suspend/restore |
| `features/dashboard/` | Bottom nav shell, home tab, summary cards |
| `features/licensing/presentation/providers/license_provider.dart` | `licenseStatusProvider` (trial/expired/blocked), `ActivateLicenseNotifier` |
| `features/licensing/presentation/screens/license_gate.dart` | `LicenseGate` — wraps whole app in `MaterialApp.builder`; shows blocked/expired screens |
| `features/licensing/presentation/widgets/license_banner.dart` | `LicenseWarningBanner` — amber countdown strip; `showSerialEntryDialog` for in-app renewal |

---

## L10n (`lib/l10n/`)

| Path | Purpose |
|---|---|
| `l10n/app_en.arb` | English string keys — edit when adding user-facing text |
| `l10n/app_localizations.dart` | Generated — never edit manually |

Run `flutter gen-l10n` after editing `app_en.arb`.

---

## Supabase Migrations (`supabase/migrations/`) — all applied live

| File | Domain |
|---|---|
| `001_identity_access.sql` | profiles, shops, branches, roles, permissions, shop_users |
| `002_inventory.sql` | measurement_units, product_categories, products, inventory, inventory_adjustments |
| `003_sales.sql` | payment_methods, customers, sales, sale_items, discounts |
| `004_supplies.sql` | suppliers, supply_orders (stub) |
| `005_financials.sql` | expense_categories, expenses, cash_reconciliations |
| `006_system.sql` | shop_settings, notification tables, export_jobs, sync_logs, handle_new_user trigger |
| `007–011` | selling_price, expiry_date, RLS fix, private schema helpers, credit_settled_at |
| `012_notifications.sql` | notification_channels, pg_cron/pg_net extensions, verify_cron_secret |
| `013_grant_service_role.sql` | Restore service_role DML grants on all public tables |
| `014_profiles_shopmate_read.sql` | shares_shop_with() — staff names visible to shopmates |
| `015_activate_membership.sql` | activate_my_membership() SECURITY DEFINER RPC |
| `016_scheduled_low_stock_notifications.sql` | pg_cron jobs (9am/9pm EAT) |
| `017–018` | credit_payments table + grants |
| `019_platform_licensing.sql` | shop_controls, license_keys, activate_license RPC |
| `020_license_periods.sql` | License duration logic |
| `021_stock_conflicts.sql` | stock_conflicts table + detect_stock_conflict trigger |
| `022_stock_conflicts_product_idx.sql` | product_id index on stock_conflicts |
| `023_offline_sync_metadata.sql` | updated_at + deleted_at on all 16 replica tables; set_updated_at() trigger |
| `024_offline_first_v2_correctness.sql` | record_credit_payment RPC (atomic, idempotent) |
| `025_one_shop_one_branch.sql` | Schema constraint for single-shop/branch model |
| `026_preserve_offline_timestamps.sql` | p_created_at param on record_credit_payment |
| `027_lock_down_trigger_function.sql` | SECURITY DEFINER audit / trigger hardening |
| `028_product_batches.sql` | Wholesale batches + sale_item_batches + rollup trigger + wholesale-only backfill |
| `029_batch_depletion.sql` | Batch-aware rollup (received−depletions), batch-level conflict detection, sale RPC `p_item_batches`, wholesale void = soft-delete ledger |
| `030_batch_discard_and_conflict_autoclose.sql` | Rollup ignores discarded lots' depletions; `detect_batch_conflict` auto-closes on recovery/discard |
| `031_batch_created_by.sql` | `product_batches.created_by` (nullable uuid) — "added by" on the batch details page |
| `032_batch_adjustments.sql` | Per-lot correction ledger; rollup + conflict gain the adjustment term (`remaining = received − depletions − corrections`), trigger recomputes; preserves 030 |
| `033_refunds.sql` | Refunds offline-first: `refunds.branch_id` + `refunds.restock` + sync metadata (updated_at/deleted_at/trigger/index) on refunds + refund_items. |
| `034_harden_handle_new_user.sql` | Pin `search_path` on `handle_new_user()` (Phase D security audit). |
| `035_lock_down_batch_trigger_functions.sql` | Revoke RPC EXECUTE on the batch trigger functions (`detect_batch_conflict`, `recompute_product_rollup`, `on_*_change`) — advisor 0028/0029, mirrors 027. |
| `036_upsert_refund_with_inventory.sql` | Atomic+idempotent refund RPC (refund+items+restock in one txn; server-side over-refund validation). Mirrors `upsert_sale_with_inventory`. Both web + native-sync push refunds through it. |

**All migrations `001`–`036` are applied to the live project** (via Supabase MCP).

---

## Tests

| Path | Purpose |
|---|---|
| `test/data/local/app_database_test.dart` | Drift DB unit tests + edge cases |
| `test/data/local/seed_service_test.dart` | Delta-pull partition logic (`partitionDelta`) |
| `test/domain/models/models_test.dart` | Model parsing — CartItem, Sale, Product, Customer, PaymentMethod |
| `test/features/auth/friendly_auth_error_test.dart` | Sign-in error classifier (offline / wrong password / rate limit) |
| `test/features/sales/sales_repository_test.dart` | Inventory enforcement, totals, DB writes, search. Uses `_StubSalesRemote` |
| `test/features/inventory/inventory_correction_test.dart` | Stock correction (15 tests) |
| `test/features/inventory/inventory_repository_test.dart` | Stock ops, offline fallback |
| `test/features/customers/customers_repository_test.dart` | Offline customer create/edit |
| `test/features/expenses/expenses_repository_test.dart` | Offline expense record |

---
*Related: [[INDEX]] · [[CURRENT_STATE]] · [[DECISIONS]] · [[COMMANDS_RUN]]*
