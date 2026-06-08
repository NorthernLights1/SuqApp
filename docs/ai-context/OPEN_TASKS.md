# Open Tasks — Suq ERP

Last updated: 2026-06-06 (session 15)

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

- [x] Email notifications for low stock — done (session 13, dispatch-notifications Edge Function)
- [x] Email notifications for overdue credits — done (session 13, manual trigger in Settings)
- [x] Settings screen: notification config (email, overdue days) — done (session 13)
- [x] `RESEND_API_KEY` set as Supabase secret (verified present, 36 chars) — done
- [x] Resend custom domain `massivedynamic.dev` wired into dispatch-notifications `from` — done
- [ ] Telegram notifications — deferred (revisit later)

### NEXT TASK — Scheduled low-stock notifications (NOT YET BUILT)
Per-sale low-stock alerts are spammy and require a notification email to be set;
replace with a server-side scheduled sweep. Design agreed, implementation pending
(was blocked on the Supabase MCP connection dropping — reconnect via `/mcp`).
Steps to implement once Supabase tools are available:
1. Enable extensions: `create extension pg_cron; create extension pg_net;`
   (both confirmed AVAILABLE, not yet installed; `supabase_vault` already installed).
2. New Edge Function `cron-notifications` (verify_jwt:false, gated by checking the
   incoming bearer == SUPABASE_SERVICE_ROLE_KEY): loops ALL shops; for each,
   recipients = owner's auth email (DEFAULT) + optional `notification_email`
   shop_setting (dedup); runs the low-stock query (inventory JOIN products where
   quantity <= low_stock_threshold) and emails via Resend. Reuse logic from
   `dispatch-notifications`. Owner email removes the old "no notification email" 400.
3. Schedule 2 cron jobs via pg_cron + pg_net: `0 6 * * *` and `0 18 * * *` (UTC)
   = 9 AM & 9 PM EAT. Store service_role key in Vault for the http_post auth header.
4. App: remove per-sale `_checkLowStock` call in `sales_provider.dart` `submit()`;
   relabel Settings "Notification email" → "Additional email (optional)" + note the
   owner is always notified.
- [ ] Resume prompt after reconnect: "Supabase MCP is back — build the scheduled
  low-stock job per OPEN_TASKS.md (steps 1-4)."

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
