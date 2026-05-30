# Open Tasks — Suq ERP

Last updated: 2026-05-30

---

## Phase 3: Sales Module ✅ COMPLETE

All files fully implemented and tested 2026-05-30. No further work needed on Phase 3.

---

## Android Setup (one-time, do before device testing)

1. Android Studio → Settings → Android SDK → SDK Tools → check **"Android SDK Command-line Tools (latest)"** → Apply
2. `flutter doctor --android-licenses` (type y to each)
3. `flutter doctor` — should show [√] Android toolchain
4. Enable USB debugging on Android 10 phone → plug in → `flutter devices` → `flutter run --dart-define-from-file=config/env.json`

---

## Phase 4 — Next Up

Start with: `git checkout -b feat/phase-4-customers-expenses`

Priority order:
1. **Customers screen** — list with credit balance, tap → transaction history (credit sales for that customer)
2. **Expenses** — record expense, pick category, branch-scoped
3. **Reports** — daily/weekly/monthly totals, low stock list
4. **Settings** — inventory mode toggle (flexible/strict), currency display, branch name edit
5. **Staff** — invite by email, assign role (owner/manager/cashier), suspend

---

## Tech Debt (tracked, not urgent)

- Hardcoded strings in `inventory_screen.dart` violate l10n rule — need `app_en.arb` entries
- No error boundaries — raw Supabase exceptions reach snackbars
- Drift offline DB not wired (Phase 5)
- `StockAdjustmentNotifier.setOpening` still exposed but never called from UI (only `ProductFormNotifier.save` calls the remote directly now for creation flow)

---

## Blocked / Deferred

- Chapa payments — out of scope v1
- Amharic l10n — translations not started
- Supabase Edge Functions for notifications — not deployed
- Barcode scanning + product images — deferred to post-v1
