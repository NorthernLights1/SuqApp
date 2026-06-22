# Commands Reference — Suq ERP

All commands run from `c:/Projects/SuqApp/` unless noted.

---

## Run app (emulator / device)
```powershell
flutter run --dart-define-from-file=config/env.json
```
Auto-detects running emulator or connected device.
Note: First Gradle build takes 2–5 min after adding Windows Defender exclusions.

## Run app (Chrome)
```powershell
flutter run -d chrome --dart-define-from-file=config/env.json
```
Primary dev target. Drift/SQLite not available on web — all DB falls back to Supabase-direct.

---

## Static analysis
```powershell
flutter analyze
```
Result: 0 issues (last run 2026-06-22). Run before every commit.

---

## Install / update dependencies
```powershell
flutter pub get
```
Run after any `pubspec.yaml` change.

Note: Riverpod 3.x + go_router v17 migration is complete (session 8). Safe to run `flutter pub upgrade` for minor/patch updates. Do NOT upgrade `sqlite3_flutter_libs` past `0.5.x` (0.6.0 is marked eol).

---

## Regenerate l10n
```powershell
flutter gen-l10n
```
Run after editing `lib/l10n/app_en.arb`.

---

## Build runner (Drift + Riverpod codegen)
```powershell
dart run build_runner build --delete-conflicting-outputs
```
Run after changing Drift table definitions in `app_database.dart` or adding `@riverpod` annotations.
Current schema version: **v16** (v12 `LocalProductBatches`, v13 `LocalSaleItemBatches` depletion ledger, v14 batch `deletedAt` discard, v15 batch `createdBy`, v16 `LocalBatchAdjustments` correction ledger). NOTE: batch-table `addColumn` migration steps are guarded `from >= 12` (the v12 createTable already builds the current schema, so a <12 upgrade must not re-add the column).

---

## Run unit tests
```powershell
flutter test
```
Result: 154 tests passing (last run 2026-06-22).
Test files:
- `test/features/auth/friendly_auth_error_test.dart` — sign-in error classification (Bug 8/9) + unknown exception fallback
- `test/data/local/app_database_test.dart` — Drift DB ops + edge cases
- `test/data/local/seed_service_test.dart` — delta-pull partition logic
- `test/features/customers/customers_repository_test.dart` — offline customer create/edit
- `test/features/expenses/expenses_repository_test.dart` — offline expense record
- `test/features/inventory/inventory_correction_test.dart` — stock correction (15 tests)
- `test/features/inventory/inventory_repository_test.dart` — stock ops, offline fallback
- `test/features/sales/sales_repository_test.dart` — enforcement, sale creation, search

---

## Windows Defender exclusions (one-time, fixes slow Gradle)
Add in Windows Security → Virus & threat protection → Exclusions:
- `C:\Users\Hp\AppData\Local\Android\Sdk`
- `C:\Users\Hp\.gradle`
- `C:\Projects\SuqApp`

---

## Apply Supabase changes (via Supabase MCP `apply_migration`)
The Supabase MCP is connected (stdio server, PAT in `SUPABASE_ACCESS_TOKEN`);
apply DDL with `mcp__supabase__apply_migration`. Dashboard SQL editor is the
manual fallback.
Migrations `001` through **`032`** — **ALL applied to the live project.** Batch
chain: `028` product_batches, `029` depletion+conflict, `030` discard+autoclose,
`031` `created_by`, `032` `batch_adjustments` correction ledger.

### Useful diagnostic queries
```sql
-- Check grants for authenticated role
SELECT table_name, string_agg(privilege_type, ', ') as grants
FROM information_schema.role_table_grants
WHERE grantee = 'authenticated' AND table_schema = 'public'
GROUP BY table_name ORDER BY table_name;

-- Check inventory mode setting
SELECT shop_id, key, value FROM shop_settings WHERE key = 'inventory_mode';

-- Fix missing grants (run if 42501 errors appear)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
```

### Session 4 SQL run
```sql
-- Updated existing shop to strict inventory mode
UPDATE shop_settings SET value = '"strict"' WHERE key = 'inventory_mode';
```

---

## Git
```powershell
git push origin <branch>
```
Repo: `https://github.com/NorthernLights1/SuqApp`
Active branch: `feat/action-feedback`

---
*Related: [[INDEX]] · [[CURRENT_STATE]] · [[FILE_MAP]]*
