# Open Tasks — Suq ERP

Last updated: 2026-06-06 (session 13)

---

## Immediate / Next Session

- [x] Remove inventory mode toggle from Settings — done (session 7)
- [x] Watch `seedNotifierProvider` in `dashboard_screen.dart` — done (session 7)
- [x] Credits tab with per-bill settlement — done (session 11)
- [x] Sales list color-coding (cash / unsettled credit / settled credit / voided) — done (session 11)
- [x] SaleDetailScreen: transaction ref, customer info, settlement notes — done (session 11)
- [x] Post-sale stale lists bug (Sales tab + Credits tab not refreshing) — done (session 11)
- [x] Fix `ListTile` ink splash invisible warnings — done (session 12)
- [x] Fix `RenderFlex` overflow by 13px in cart item row — done (session 12)
- [x] Staff invite 403 + duplicate email — done (session 12, Edge Function v4)
- [ ] "Gaps" view — surface products sold as `untracked` to prompt owner to add them to inventory

---

## Notifications Phase (branch: `feat/notifications`)

- [x] Email + Telegram notifications for low stock — done (session 13, dispatch-notifications Edge Function)
- [x] Email + Telegram notifications for overdue credits — done (session 13, manual trigger in Settings)
- [x] Settings screen: notification config (email, Telegram bot token/chat ID, overdue days) — done (session 13)
- [ ] One-time setup: add `RESEND_API_KEY` as Supabase secret (supabase.com → Edge Functions → Secrets); optionally verify own domain in Resend and update `from` in dispatch-notifications Edge Function
- [ ] Telegram notifications — deferred (was abandoned this session; revisit later)

---

## Planned — Re-add lint tools (blocked on upstream)

- [ ] Re-add `custom_lint` + `riverpod_lint` once `custom_lint 0.9+` resolves the `analyzer ^9.0.0` vs `^8.0.0` conflict with `riverpod_lint 3.x`. Check pub.dev before attempting.

---

## Phase 5 — Remaining

- [ ] Inventory writes write-through to Drift (product create/edit, stock add/correct)
- [ ] Expense writes offline (record expense when offline)
- [ ] Auto-trigger `SyncService.sync()` on connectivity restored
- [ ] Widget tests for key screens (NewSaleScreen, SalesScreen)

---

## Deferred / Manual Steps

- [ ] Supabase Dashboard: enable Leaked Password Protection (Auth → Settings → Password Security — cannot do via SQL)
- [ ] Android Setup (one-time, do before device testing):
  1. Android Studio → Settings → Android SDK → SDK Tools → check **"Android SDK Command-line Tools (latest)"** → Apply
  2. `flutter doctor --android-licenses` (type y to each)
  3. `flutter doctor` — should show [√] Android toolchain
  4. Enable USB debugging on Android 10 phone → plug in → `flutter devices` → `flutter run --dart-define-from-file=config/env.json`
  5. Add `C:\Users\Hp\AppData\Local\Android\Sdk`, `C:\Users\Hp\.gradle`, `C:\Projects\SuqApp` to Windows Defender exclusions

---

## Tech Debt (tracked, not urgent)

- Hardcoded strings in screens violate l10n rule (`app_en.arb` unused)
- No error boundaries — raw Supabase exceptions reach snackbars
- Permission cache TTL not implemented (role changes need app restart)
- `Decimal.parse()` without try-catch in models — can throw on malformed DB data
- Inventory writes (create/edit product, stock adjust) not yet write-through to Drift
- `FilteringTextInputFormatter` allows multiple decimal points — caught by `Decimal.tryParse` at validation but could be rejected earlier

---

## Blocked / Deferred

- Chapa payments — out of scope v1
- Amharic l10n — translations not started
- Staff invite for existing Supabase users — Edge Function errors; users must use a fresh email
- Barcode scanning + product images — deferred post-v1
- Monetization / multi-branch pricing tiers — decision pending
