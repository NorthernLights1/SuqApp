# UI Polish — Feature Contract

**Status: DRAFT** (agreed in discussion; may change before work starts)
**Created: 2026-06-24** · Not started · No branch yet

> Presentation-only polish pass. This document is the agreed scope. Implementation
> has NOT begun. Status is intentionally DRAFT — Temesgen may revise before go.

---

## Goal
Presentation-focused UI polish: warmer visual system, light/dark themes,
Amharic-ready typography + localization plumbing, ledger-grade number formatting,
real loading/empty/error states, and two known layout defects fixed — held to a
real design standard. **No changes to business logic, data model, sync, SQL, or
money math.**

## Design standard
Polish is held to `ecc/frontend-design-direction` guidance + an
Emil-Kowalski-style motion-craft bar: intentional easing (no linear/default
fling), purposeful micro-interactions, and at least one memorable,
product-appropriate detail per key screen — all within the budget-hardware motion
budget. A "memorable detail" must live **inside existing layouts** (a
motion/micro-interaction/typographic moment), never a new structure. Taste raises
the bar on Phases 1/4/6; it does not expand scope.

## Branch / PR
New branch off `main`; one PR acceptable, commits phased and reviewable;
**Phase 5 kept in separable commits** (the only behavior-adjacent phase, so it can
be split into its own PR if review gets heavy).

## Phases

**0 — Theme foundation:** terracotta `#C56A3D` + warm neutrals (global via
`ThemeData`); **one** `ThemeExtension` for Suq tokens (warm surfaces + status
colors: debt/paid/lowStock/expired), standard roles stay in seeded `ColorScheme`;
spacing/radius/type tokens; **fix all known hardcoded color sites** *except*
intentional white-on-accent text/icons (those stay white so they don't vanish in
dark mode).

**1 — Typography + money:** `Inter` + `Noto Sans Ethiopic` fallback; centralize
fonts; tabular figures + right-aligned amounts in sales/reports/credits/inventory
where appropriate; formatting via existing `currency_formatter`; **money math
unchanged**.

**2 — Dark mode:** warm dark theme; Settings `System/Light/Dark`, persisted
locally as `theme_mode`, default `System`.

**3 — Localization + Amharic plumbing:** `app_am.arb` scaffold; Settings
`English/Amharic`, persisted locally as `locale`, default English; wire
`supportedLocales` + delegates in `app.dart`, run `gen-l10n` (missing keys fall
back to English); new/touched strings via l10n; existing hardcoded strings on
touched screens moved opportunistically + listed. **Handoff: Claude produces the
English string list → Temesgen supplies Amharic → Claude wires it.** Claude does
NOT author translations.

**4 — Real states:** hand-rolled loading skeleton, empty, and error/retry widgets
on inventory/sales/reports/credits; "as of last sync" display where the timestamp
already exists.

**5 — Known layout defects** *(separable commits):*
- **Sales customer/payment:** docked bottom selector when collapsed; tap expands as
  a draggable/scrollable bottom sheet up to `0.6 × screenHeight`, internal scroll
  beyond; checkout/total CTA stays reachable; behaves with the keyboard.
- **Inventory batch insert:** **pure widget reorder** earlier in the form; no change
  to validation, submit order, stock logic, persistence, or add-stock behavior.
- **Reports:** cards → `TabBar`/`TabBarView` inside `reports_screen` (not router);
  horizontally scrollable tabs on narrow screens; each tab owns its
  loading/empty/error; state persists via existing Riverpod provider cache; confirm
  nothing else points directly at the individual report screens first.

**6 — Motion + haptics:** short compositor-friendly transitions only
(opacity/transform), `≤250ms`, respect reduce-motion; lightweight list animations
where cheap; sale-complete confirmation + light haptic (built-in `HapticFeedback`);
no blur/glass.

## Out of scope
Business logic, SQL/data model, sync, money calculations, new reports/charts/graphs,
Arabic/RTL, new dependencies, any layout redesign beyond the three Phase 5 fixes.

## Defaults locked
Terracotta `#C56A3D` · Inter + Noto Ethiopic · System+manual theme toggle · local
persistence (`theme_mode`, `locale`) · no new deps · no charts.

## Edge cases
- Long Amharic labels wrap/ellipsize without overflow.
- Missing Ge'ez glyphs render via Noto Ethiopic.
- Debt-red / paid-green pass contrast in dark mode.
- Negative, zero, and very-large amounts format cleanly and stay aligned.
- Reduce-motion enabled minimizes animation.
- No saved prefs → theme `System`, language English.

## Acceptance checklist
- [ ] Warm light theme consistent; no leftover cool-blue on touched surfaces.
- [ ] All known hardcoded colors fixed (except intentional on-accent whites).
- [ ] Dark theme works + persists; toggle in Settings.
- [ ] Locale toggle persists; Amharic renders with English fallback.
- [ ] Money uses tabular figures + right alignment in sales/reports/credits/inventory.
- [ ] Inventory/sales/reports/credits show loading/empty/error states.
- [ ] Sales selector docks, expands only to `0.6 × screenHeight`, no overflow, CTA reachable.
- [ ] Inventory batch insert visible early; no behavior change.
- [ ] Reports use tabs; per-tab states work.
- [ ] Motion/haptics present + budget-safe.
- [ ] Key screens (dashboard, new-sale, reports) each have intentional easing + one
      memorable detail; nothing reads as default Material. *(Subjective — Temesgen's sign-off.)*
- [ ] `flutter analyze` clean; no behavior/logic diffs.
- [ ] Manual screenshots verified at 320 / 375 / 414, light + dark.

## Known risks
- Phase 5 is the only behavior-adjacent work (sheet + keyboard interplay, tab
  back-behavior, form reorder) — separable commits + before/after screenshots +
  manual-test notes.
- Translation string list will likely be sizeable (touched-screen strings).
- One acceptance gate (design taste) is subjective and verified by eye, not a command.

## First actions on "go" (no code before these)
1. Inspect `app.dart`, `app_theme.dart`, sales/reports/inventory screens, `app_en.arb`.
2. Hand Temesgen the **English string list** for Amharic translation.
3. Then begin Phase 0.
