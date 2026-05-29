# Open Tasks — Suq ERP

Last updated: 2026-05-29

---

## Immediate — Phase 3: Sales Module

Build in this order:

1. **`suq/lib/domain/models/sale.dart`**
   `Sale`, `SaleItem`, `Discount`, `Refund` models. Use `Decimal` not `double`. Include `product_name_snapshot`.

2. **`suq/lib/features/sales/data/sales_remote.dart`**
   Supabase: create sale + items + inventory_adjustment in one transaction. Respect `inventory_mode` from `shop_settings`.

3. **`suq/lib/features/sales/domain/sales_repository.dart`**
   Interface + implementation (Supabase-only for now, Drift stub).

4. **`suq/lib/features/sales/presentation/providers/sales_provider.dart`**
   Cart state (active sale items), product search, payment method selection.

5. **`suq/lib/features/sales/presentation/screens/new_sale_screen.dart`**
   Product search → add to cart → set qty/price → apply discount → pick payment method → submit.
   Must check `PermissionService` for `sales.create`.

6. **`suq/lib/features/sales/presentation/screens/sales_screen.dart`**
   List today's sales. Filter by date. Tap → detail.

7. **Sale detail + void flow**
   Void requires reason + `PermissionService` check for `sales.void`.
   Refund checks `sales.refund_own` vs `sales.refund_any`.

8. **Inventory adjustment on sale**
   Auto-create `inventory_adjustments` row (`type: 'sale'`) per sale item.
   Respect `inventory_mode`: `flexible` = warn + flag, `strict` = block.

9. **Wire sales routes in router**
   Replace `_ShellPage` stubs for `/sales` and `/sales/new` in `app_router.dart`.

10. **Update dashboard summary cards**
    Replace static "ETB 0" with real today's totals from Supabase.

---

## Follow-up — Phase 4 (after sales)

- Inventory: product CRUD, stock levels, manual adjustments, low-stock alerts
- Customers: list, credit balance, transaction history
- Expenses: record expense, category picker
- Reports: daily/weekly/monthly, export via `ExportService`
- Staff: invite by email, assign role, suspend
- Settings: inventory mode toggle, currency, branch management

---

## Blocked / Unclear

- **Drift offline DB** — not designed yet; needed for Phase 5
- **Chapa payments** — out of scope v1; `payment_methods` table ready
- **Amharic l10n** — l10n layer ready; translations not started
- **Supabase Edge Functions** — `NotificationService` logs `pending` rows only; no function deployed yet
- **Android builds** — blocked until Android Studio installed
