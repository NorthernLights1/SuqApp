# Decisions — Suq ERP

---

## Decision: Flutter + Supabase as core stack
Date: 2026-05-29
Status: Active

Context: Need a mobile-first ERP that works offline and has a real-time capable backend.
Decision: Flutter for cross-platform mobile/web; Supabase for auth, DB, realtime, and storage.
Reason: Flutter gives one codebase for Android + iOS + web. Supabase gives Postgres with RLS, auth, and realtime out of the box without managing a server.
Impact: All backend queries go through `supabase_flutter`. Local offline uses Drift (SQLite).

---

## Decision: Drift for offline-first local DB
Date: 2026-05-29
Status: Active

Context: App must be fully functional with no internet. Supabase-only would break offline.
Decision: Use Drift (SQLite) as the primary write target. Sync to Supabase in background.
Reason: Drift is type-safe, works on all Flutter platforms, and has good migration support.
Impact: All writes go local first. `SyncService` pushes to Supabase when online. Drift schema must mirror the subset of Supabase tables needed offline. Not yet wired — Phase 5.

---

## Decision: Riverpod for state management
Date: 2026-05-29
Status: Active

Context: Needed a scalable, testable state layer that works well with async Supabase calls.
Decision: `flutter_riverpod` + `riverpod_annotation` for code-gen providers.
Reason: Better compile-time safety than Provider, cleaner than BLoC for this scale, good async support with `AsyncNotifier` and `FutureProvider`.
Impact: Every feature has its own providers folder. No global state outside of auth session.

---

## Decision: Go Router for navigation
Date: 2026-05-29
Status: Active

Context: Need declarative routing with redirect guards for auth and onboarding.
Decision: `go_router` with an `_AuthRefreshNotifier` that listens to Supabase auth stream.
Reason: Go Router supports async redirects, deep linking, and URL-based navigation for web.
Impact: Router is created once (`late final` in `ConsumerStatefulWidget`). Auth changes trigger redirect re-evaluation automatically. See BUGS_AND_FIXES.md for the router recreation bug.

---

## Decision: `decimal` package for all monetary values
Date: 2026-05-29
Status: Active

Context: Floating point arithmetic is unsuitable for money (e.g. 0.1 + 0.2 ≠ 0.3).
Decision: Use `decimal` package everywhere money is handled.
Reason: Exact decimal arithmetic, matches PostgreSQL `numeric` type in the DB.
Impact: All sale totals, prices, quantities, expenses use `Decimal` not `double`. Never cast to double for math.

---

## Decision: Flutter app lives in `suq/` subdirectory
Date: 2026-05-29
Status: Active

Context: The repo root already contains the Antigravity Kit / ui-ux-pro-max skill content.
Decision: Flutter project created at `suq/` not at the repo root.
Reason: Avoids conflicts with existing repo structure.
Impact: All Flutter commands must be run from `c:/Projects/MobERP/suq/`, not from root.

---

## Decision: SQL migrations run manually in Supabase dashboard
Date: 2026-05-29
Status: Active

Context: No Supabase CLI set up on dev machine.
Decision: SQL files in `supabase/migrations/` are reference files, applied manually via SQL Editor.
Reason: Simpler setup with no CLI dependency.
Impact: Schema changes require manually running SQL in Supabase dashboard. Consider Supabase CLI in future.

---

## Decision: Separate GitHub repo for Suq
Date: 2026-05-29
Status: Active

Context: Original repo (`nextlevelbuilder/ui-ux-pro-max-skill`) is a different project. Developer has no push access.
Decision: Created new repo at `NorthernLights1/Suq`. Added as remote `suq`.
Reason: Clean separation of concerns; developer owns the Suq repo.
Impact: Push with `git push suq <branch>`. The `origin` remote still points to the old repo.
