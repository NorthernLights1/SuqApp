# Current State — Suq ERP

Last updated: 2026-05-29

---

## What We Are Building

**Suq** — mobile ERP for small shop owners. Flutter + Supabase.
Package: `com.temesgen.suq` | Repo: `NorthernLights1/Suq`
Flutter app lives in: `suq/` subdirectory of `c:/Projects/MobERP/`
Push target: `git push suq <branch>` (not `origin`)

---

## Current Phase

**Phase 2 complete. Phase 3 (Sales module) is next.**

| Phase | Status |
|---|---|
| Phase 0 — Bootstrap + SQL migrations | ✅ Done |
| Phase 1 — Core services (Permission, Sync, Notification, Export) | ✅ Done |
| Phase 2 — Auth, Onboarding, Dashboard shell | ✅ Done |
| Phase 3 — Sales module | 🔲 Not started — next |
| Phase 4 — Inventory, Customers, Expenses, Reports, Staff, Settings | 🔲 Not started |
| Phase 5 — Drift offline DB wiring + tests | 🔲 Not started |

Active branch: `feat/phase-2-auth-onboarding` (pushed, not yet merged to main)

---

## Recently Changed (this session)

- `suq/lib/main.dart` — Supabase init + ProviderScope
- `suq/lib/app.dart` — changed to `ConsumerStatefulWidget`, router cached via `late final`
- `suq/lib/shared/router/app_router.dart` — `createRouter()` takes no args, `_AuthRefreshNotifier` created per instance, simplified redirect logic
- `suq/lib/shared/router/app_routes.dart` — removed `part of`, now standalone import
- `suq/lib/features/auth/presentation/providers/auth_provider.dart` — `AuthNotifier` (signIn/signUp/signOut)
- `suq/lib/features/auth/presentation/providers/shop_provider.dart` — `currentShopProvider`, `currentShopBranchesProvider`, `activeBranchProvider`
- `suq/lib/features/auth/presentation/screens/login_screen.dart` — full login UI
- `suq/lib/features/auth/presentation/screens/signup_screen.dart` — full signup UI
- `suq/lib/features/onboarding/presentation/providers/onboarding_provider.dart` — shop + branch creation, default settings write
- `suq/lib/features/onboarding/presentation/screens/onboarding_screen.dart` — 4-step flow
- `suq/lib/features/dashboard/presentation/screens/dashboard_screen.dart` — bottom nav, summary cards, quick actions
- `suq/lib/domain/models/shop.dart` — `Shop` + `Branch` models
- `suq/lib/shared/widgets/` — `AppTextField`, `AppButton`, `AppLoadingOverlay`
- `suq/CLAUDE.md` — Flutter project rules + AI context usage
- `docs/ai-context/` — full context system created

---

## What Works Right Now

- `flutter run -d chrome` runs successfully
- Signup creates Supabase user + profile (DB trigger fix applied — see BUGS_AND_FIXES.md)
- Login redirects → onboarding (no shop) or dashboard (shop exists)
- Onboarding: 4 steps, steps 3–4 skippable, writes shop + branch + default shop_settings
- Dashboard: bottom nav, summary cards (static ETB 0), quick actions grid, sign out

---

## Current Blocker / Risk

- **Android SDK not installed** — Chrome is the only working test target
- **Drift not wired** — app is Supabase-only; offline mode not functional yet
- No error boundaries — raw Supabase exceptions surface directly to UI snackbars

---

## Exact Next Action

Start Phase 3: Sales module.
First file to create: `suq/lib/domain/models/sale.dart`
Branch to create: `git checkout -b feat/phase-3-sales`

See `OPEN_TASKS.md` for the full Phase 3 build order.
