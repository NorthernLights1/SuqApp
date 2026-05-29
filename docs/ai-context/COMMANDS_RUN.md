# Commands Reference — Suq ERP

All Flutter commands run from `c:/Projects/MobERP/suq/` unless noted.

---

## Run app (Chrome)
```bash
cd suq && flutter run -d chrome
```
Result: Works. Chrome is the only confirmed target (Android SDK not installed).
Rerun next session: Yes — to test Phase 3 sales features.

---

## Static analysis
```bash
cd suq && flutter analyze
```
Result: 0 issues (as of last run on feat/phase-2-auth-onboarding).
Rerun next session: Yes — after every code change, before committing.

---

## Install dependencies
```bash
cd suq && flutter pub get
```
Result: 143 packages resolved. Requires Windows Developer Mode enabled.
Rerun next session: Only if `pubspec.yaml` changes.

---

## Regenerate l10n
```bash
cd suq && flutter gen-l10n
```
Result: Generates `suq/lib/l10n/app_localizations.dart` + `app_localizations_en.dart`.
Rerun next session: Only if `suq/lib/l10n/app_en.arb` is modified.

---

## Build runner (Drift + Riverpod codegen)
```bash
cd suq && dart run build_runner build --delete-conflicting-outputs
```
Result: Not yet run — no generated code needed until Phase 5 (Drift).
Rerun next session: No — until Drift schema is added.

---

## Create new branch
```bash
cd c:/Projects/MobERP && git checkout -b feat/phase-3-sales
```
Result: Not yet run. This is the next branch to create.
Rerun next session: Yes — run this first when starting Phase 3.

---

## Push to Suq repo
```bash
git push suq <branch-name>
```
Result: Works. Remote `suq` = `https://github.com/NorthernLights1/Suq.git`
Note: `origin` = `nextlevelbuilder/ui-ux-pro-max-skill` (no push access). Always use `suq`.

---

## Apply Supabase migrations (manual)
No CLI. Use Supabase Dashboard → SQL Editor.
Run files in order: 001 → 002 → 003 → 004 → 005 → 006
Status: All 6 migrations applied to live project. DB trigger fix also applied manually.
Rerun next session: No — unless schema changes are needed.

---

## Enable Windows Developer Mode (one-time)
```powershell
start ms-settings:developers
```
Result: Done. Toggle Developer Mode on. Required for Flutter plugin symlinks on Windows.
Rerun next session: No — already enabled.
