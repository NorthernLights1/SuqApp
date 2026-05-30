# Commands Reference — Suq ERP

All commands run from `c:/Projects/SuqApp/` unless noted.

---

## Run app (emulator / device)
```powershell
flutter run --dart-define-from-file=config/env.json
```
Result: Auto-detects running emulator or connected device.
Note: First Gradle build takes 2–5 min after adding Windows Defender exclusions.

## Run app (Chrome fallback)
```powershell
flutter run -d chrome --dart-define-from-file=config/env.json
```
Result: Works. Use when emulator is not running.

---

## Static analysis
```powershell
flutter analyze
```
Result: 0 issues (last run 2026-05-30). Run before every commit.

---

## Install / update dependencies
```powershell
flutter pub get
```
Result: Works. Run after any `pubspec.yaml` change.
Current notable packages: `google_fonts ^6.2.1` (added 2026-05-30)

---

## Regenerate l10n
```powershell
flutter gen-l10n
```
Run only after editing `lib/l10n/app_en.arb`.

---

## Build runner (Drift + Riverpod codegen)
```powershell
dart run build_runner build --delete-conflicting-outputs
```
Not yet needed — run when Drift schema is added (Phase 5).

---

## Windows Defender exclusions (one-time fix for slow Gradle)
Add these folders in Windows Security → Virus & threat protection → Exclusions:
- `C:\Users\Hp\AppData\Local\Android\Sdk`
- `C:\Users\Hp\.gradle`
- `C:\Projects\SuqApp`
Without these, first Gradle build can take 1+ hour.

---

## Apply Supabase migrations (manual)
No CLI. Use Supabase Dashboard → SQL Editor.
Migrations: `supabase/migrations/001` through `009` — all applied to live project.

---

## Git
```powershell
git push origin <branch>
```
Repo: `https://github.com/NorthernLights1/Suq.git`
