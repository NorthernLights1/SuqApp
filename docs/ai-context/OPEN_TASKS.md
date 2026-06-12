# Open Tasks — Suq ERP

Last updated: 2026-06-12 (session 17)

---

## Session 17 follow-ups

- [ ] **`security` branch — merge when ready.** Published, NOT merged. Trial
  (14 days) + 10-digit serial activation (per-key duration, no stacking, 7-day
  countdown banner) + remote per-shop block. Migrations 019/020 already applied
  live. Operator SQL for generating keys / blocking is in the session notes.
- [ ] **Verify on device:** partial-settlement shows all payment logs; voided
  credit drops out of all credit views (fixes are in but unverified on-device).
- [ ] **Local Drift cache encryption (SQLCipher)** — Supabase is encrypted in
  transit + at rest; on-device cache is plaintext. Defer past the pilot.
- [x] Email overdue/low-stock reminders to ALL configured `notification_email`
  rows — done (dispatch-notifications v5).

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

### Scheduled low-stock notifications — DONE (server-side cron, replaces per-sale)
- [x] Enabled `pg_cron` + `pg_net` (migration 016).
- [x] Edge Function `cron-notifications` (verify_jwt:false; gated by Vault `cron_secret`
  via `public.verify_cron_secret` RPC). Loops ALL shops; recipients = owner auth email
  (DEFAULT) + optional `notification_email` shop_setting; sends via Resend from
  `notifications@massivedynamic.dev`. Verified end-to-end (200, email sent).
  - v2: sends ONE combined daily digest per shop — LOW STOCK section
    (inventory JOIN products where quantity <= low_stock_threshold) + OVERDUE CREDITS
    section (sales is_credit, not settled, completed, older than `overdue_credit_days`
    setting, default 7). Each section appears only if non-empty; no email if both empty.
- [x] Two pg_cron jobs: `low-stock-am` (`0 6 * * *`) and `low-stock-pm` (`0 18 * * *`)
  UTC = 9 AM & 9 PM EAT. They call the function via `net.http_post`, reading the
  `cron_secret` from Vault at run time.
- [x] App: removed per-sale `_checkLowStock` from `sales_provider.dart`; relabeled the
  Settings email field to "Additional notification email (optional)" (owner always notified).
- Owner email as default recipient also removed the old "no notification email" 400.
- Note: the old per-sale path (`dispatch-notifications` low_stock) is now unused but
  still deployed; the manual "Send overdue reminders" button still uses it.

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

## Security — Deferred (decide before wide rollout)

- [ ] Encrypt the local on-device Drift/SQLite cache (SQLCipher). Supabase is
  encrypted in transit (TLS) and at rest (AWS AES-256), but the offline copy
  on each phone is currently plaintext — exposed if a device is lost/stolen.
  Deferred for the initial debug-APK pilot; do before wider distribution.
  (Raised session 16 while shipping the GitHub Actions APK build.)

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
