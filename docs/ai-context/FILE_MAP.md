# File Map — Suq ERP

Focus on files that matter for development. Excludes generated files and platform boilerplate.

---

## Entry Points

| Path | Purpose | Edit when |
|---|---|---|
| `suq/lib/main.dart` | App entry — Supabase init + ProviderScope + runApp | Rarely. Adding global init only. |
| `suq/lib/app.dart` | MaterialApp.router — theme, router, l10n config | Changing theme, locale config, or router wiring |
| `suq/pubspec.yaml` | All dependencies + flutter config | Adding/removing packages |
| `suq/l10n.yaml` | l10n generation config (arb-dir, template file) | Rarely |

---

## Core Layer (`suq/lib/core/`)

| Path | Purpose | Edit when |
|---|---|---|
| `core/constants/app_constants.dart` | App name, default locale, default currency, sync warning hours | Changing app-wide defaults |
| `core/constants/supabase_constants.dart` | Supabase URL + anon key | Never (or on project change) |
| `core/constants/setting_keys.dart` | All `shop_settings` key names as constants | Adding a new shop setting |
| `core/errors/app_error.dart` | Sealed error hierarchy (NetworkError, AuthError, PermissionError, etc.) | Adding a new error type |
| `core/services/permission_service.dart` | Central RBAC — queries `shop_users` → `roles` → `permissions` | Changing permission logic |
| `core/services/sync_service.dart` | Offline sync orchestration stub | Wiring Drift in Phase 5 |
| `core/services/notification_service.dart` | Reads `notification_configs`, writes `notification_logs` | Adding a new notification type |
| `core/services/export_service.dart` | Creates `export_jobs` rows for PDF/Excel | Adding export formats |

---

## Domain Layer (`suq/lib/domain/`)

| Path | Purpose | Edit when |
|---|---|---|
| `domain/models/shop.dart` | `Shop` + `Branch` pure Dart models | Changing shop/branch shape |
| `domain/interfaces/permission_service_interface.dart` | `IPermissionService` contract | Changing permission API |
| `domain/interfaces/sync_service_interface.dart` | `ISyncService` + `SyncStatus` enum | Changing sync API |
| `domain/interfaces/notification_service_interface.dart` | `INotificationService` + `NotificationType` enum | Adding notification types |
| `domain/interfaces/export_service_interface.dart` | `IExportService` + enums | Adding export formats/periods |

---

## Shared Layer (`suq/lib/shared/`)

| Path | Purpose | Edit when |
|---|---|---|
| `shared/router/app_router.dart` | GoRouter instance, `_AuthRefreshNotifier`, redirect logic | Adding routes or changing auth redirect behavior |
| `shared/router/app_routes.dart` | All route path constants (`AppRoutes.login`, etc.) | Adding a new route |
| `shared/theme/app_colors.dart` | All color tokens | Changing brand colors |
| `shared/theme/app_theme.dart` | Material3 ThemeData | Changing global widget styling |
| `shared/theme/app_text_styles.dart` | Named text styles (headline1, body, label, amount) | Adding or changing typography |
| `shared/widgets/app_text_field.dart` | Reusable form text field | Changing global input behavior |
| `shared/widgets/app_button.dart` | Primary/outlined button with loading state | Changing global button behavior |
| `shared/widgets/app_loading_overlay.dart` | Semi-transparent loading overlay | Rarely |

---

## Auth Feature (`suq/lib/features/auth/`)

| Path | Purpose | Edit when |
|---|---|---|
| `auth/presentation/providers/auth_provider.dart` | `AuthNotifier` (signIn/signUp/signOut), session providers | Changing auth flow |
| `auth/presentation/providers/shop_provider.dart` | `currentShopProvider`, `currentShopBranchesProvider`, `activeBranchProvider` | Adding shop/branch queries |
| `auth/presentation/screens/login_screen.dart` | Login form | Changing login UI |
| `auth/presentation/screens/signup_screen.dart` | Signup form | Changing signup UI |

---

## Onboarding Feature (`suq/lib/features/onboarding/`)

| Path | Purpose | Edit when |
|---|---|---|
| `onboarding/presentation/providers/onboarding_provider.dart` | `OnboardingNotifier` — creates shop + branch + default settings | Changing onboarding data writes |
| `onboarding/presentation/screens/onboarding_screen.dart` | 4-step onboarding UI | Changing onboarding flow/UI |

---

## Dashboard Feature (`suq/lib/features/dashboard/`)

| Path | Purpose | Edit when |
|---|---|---|
| `dashboard/presentation/screens/dashboard_screen.dart` | Bottom nav shell, home tab, summary cards, quick actions | Adding nav items or home widgets |

---

## L10n (`suq/lib/l10n/`)

| Path | Purpose | Edit when |
|---|---|---|
| `l10n/app_en.arb` | English string keys + values | Adding any user-facing string |
| `l10n/app_localizations.dart` | Generated — do not edit manually | Never (regenerate with `flutter gen-l10n`) |

---

## Supabase Migrations (`supabase/migrations/`)

| File | Domain | Tables |
|---|---|---|
| `001_identity_access.sql` | Auth & RBAC | profiles, shops, branches, roles, permissions, role_permissions, shop_users |
| `002_inventory.sql` | Inventory | measurement_units, product_categories, products, inventory, inventory_adjustments |
| `003_sales.sql` | Sales | payment_methods, customers, sales, sale_items, discounts, refunds, refund_items |
| `004_supplies.sql` | Supplies (stub) | suppliers, supply_orders, supply_order_items |
| `005_financials.sql` | Financials | expense_categories, expenses, cash_reconciliations |
| `006_system.sql` | System | shop_settings, notification_channels/types/configs/logs, export_jobs, sync_logs, handle_new_user trigger |

---

## Not Yet Built (placeholders only)

- `features/sales/` — domain, data, providers, screens
- `features/inventory/` — domain, data, providers, screens
- `features/customers/` — domain, data, providers, screens
- `features/expenses/` — domain, data, providers, screens
- `features/reports/` — providers, screens
- `features/staff/` — domain, data, providers, screens
- `features/settings/` — providers, screens
- `data/local/` — Drift DB (Phase 5)
- `data/repositories/` — combined local+remote repos (Phase 5)
