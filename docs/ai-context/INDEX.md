# AI Context Index — Suq ERP

Read this file first at the start of every new session.
Then read only the specific files you need — do not load all of them.

---

## Files

| File | Purpose | Read when |
|---|---|---|
| `INDEX.md` | This file. Table of contents + usage rules. | Always first |
| `CURRENT_STATE.md` | What the project is, where it stands, key constraints | Starting a new session |
| `OPEN_TASKS.md` | Prioritized task list — what to do next | Planning work or resuming a task |
| `DECISIONS.md` | Architecture and tech decisions with rationale | Before changing structure, choosing a lib, or overriding a pattern |
| `FILE_MAP.md` | Important files, their purpose, and when to edit them | Before editing an unfamiliar file or adding a new feature |
| `BUGS_AND_FIXES.md` | History of bugs encountered and how they were fixed | Debugging, or before touching auth/router/Supabase trigger code |
| `COMMANDS_RUN.md` | Useful CLI commands with results | Running builds, analysis, migrations, or pub commands |
| `ARCHIVE/` | Old context no longer active | Rarely — only if explicitly asked |

---

## Usage Rules

- Read `INDEX.md` + `CURRENT_STATE.md` + `OPEN_TASKS.md` at session start.
- Read `DECISIONS.md` before changing architecture or switching a library.
- Read `BUGS_AND_FIXES.md` before touching auth, router, or Supabase triggers.
- Read `FILE_MAP.md` when navigating an unfamiliar part of the codebase.
- Never load all files at once unless asked.
- Before context compacts: update `CURRENT_STATE.md`, `OPEN_TASKS.md`, and any relevant log files.
