# CLAUDE.md — Suq ERP (Flutter)

This file provides guidance to Claude Code when working in this repository.

---

## Project

**Suq** is a mobile ERP for small shop owners built with Flutter and Supabase.
Replaces paper ledgers with digital sales, inventory, credit tracking, and reporting.

Package: `com.temesgen.suq` | Repo: `NorthernLights1/SuqApp`

---

## Key Rules (non-negotiable)

1. No hardcoded values — all config via `shop_settings` or `core/constants/`
2. All modules behind interfaces — never call Supabase/PDF/Excel libs directly from features
3. All monetary values use `decimal` package — never `double`
4. RBAC always through `PermissionService` — never check `role == 'owner'` in UI
5. No hardcoded strings in widgets — all user-facing text in `lib/l10n/app_en.arb`
6. Writes go local (Drift) first, sync to Supabase in background
7. Run `flutter analyze` before every commit — must be clean

---

## Git Workflow

- Branch: `git checkout -b feat/...` or `fix/...`
- Push: `git push origin <branch>`
- PR at: https://github.com/NorthernLights1/SuqApp

---

## Environment Setup

Secrets are **never** hardcoded. They live in `config/env.json` (gitignored).

```bash
cp config/env.json.example config/env.json
# then fill in your Supabase URL and anon key
```

## Dev Commands

```bash
# Always pass --dart-define-from-file so the app gets its credentials
flutter run -d chrome --dart-define-from-file=config/env.json
flutter build web --dart-define-from-file=config/env.json

flutter analyze                          # must pass clean before commit
flutter pub get                          # install/update deps
flutter gen-l10n                         # regenerate after editing app_en.arb
```

---

## AI Context Usage

This project uses `docs/ai-context/` as external memory.

At the start of a new session, read only:
- `docs/ai-context/INDEX.md`
- `docs/ai-context/CURRENT_STATE.md`
- `docs/ai-context/OPEN_TASKS.md`

Do not read the entire `docs/ai-context/` folder unless explicitly asked.

Before compacting context, update the relevant files in `docs/ai-context/`:
- `CURRENT_STATE.md`
- `OPEN_TASKS.md`
- `DECISIONS.md`
- `BUGS_AND_FIXES.md`
- `COMMANDS_RUN.md`
- `FILE_MAP.md`

Do not paste full conversation history into these files.
Do not paste large source files into these files.
Keep entries concise, factual, and easy for a future session to scan.

When uncertain, read `INDEX.md` first, then only the specific context file needed.
