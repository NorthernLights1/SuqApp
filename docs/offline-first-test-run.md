# Offline-First — Manual Test Run

Fill this in as you go. For each test: tick **one** result box (`[x]`), write what you
actually saw, and (for sync tests) confirm it reached Supabase **exactly once**.

> **Goal:** prove that writes work offline, survive an app restart, and sync up
> exactly once with the right data when you reconnect — no loss, no duplicates.

---

## Run details

- Tester: ______________________
- Date / time: ______________________
- Device & OS (e.g. Android phone / Chrome dev): ______________________
- Build / branch: `offline-first_v2`  commit: ______________________
- Test account email: ______________________

**How I went offline:**  `[ ]` Airplane mode   `[ ]` Chrome DevTools → Offline
**Ground truth open?**   `[ ]` Supabase → Table Editor in a second window

---

## Phase 1 — Online baseline (network ON)

### T1 — Sign in
- Do: open app, sign in. Expect: dashboard loads with today's totals.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T2 — Make a sale (online)
- Do: sell 2 items, cash. Expect: appears in Sales instantly; dashboard total rises; **stock drops**.
- In Supabase (sale + items + inventory reduced)? `[ ] Yes  [ ] No`
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T3 — Add/edit a product + set stock (online)
- Do: add a product, set stock. Expect: shows in Inventory; in Supabase.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T4 — Credit sale + record payment (online)
- Do: make a credit sale, then record a payment. Expect: remaining balance drops correctly; `credit_payments` row in Supabase.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T5 — Add an expense (online)
- Do: add an expense. Expect: shows in Expenses; in Supabase.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T6 — Reports match (online)
- Do: open Reports. Expect: sales / profit / expense totals match what you just did.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

---

## Phase 2 — Offline writes (Airplane mode ON)

> Note the wall-clock time of each entry — you'll verify timestamps in Phase 4.

### T7 — Make a sale offline
- Do: sell items. Expect: succeeds **immediately** (no error/endless spinner); shows in list; **stock drops locally**; dashboard updates.
- Time made: __________
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T8 — Adjust stock / add product offline
- Do: change stock or add a product. Expect: succeeds.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T9 — Record a credit payment offline
- Do: record a payment on a credit sale. Expect: succeeds; balance updates.
- Time made: __________
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T10 — Add an expense offline
- Do: add an expense. Expect: succeeds.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T11 — Offline indicator
- Do: look for a "pending sync" / offline indicator. Expect: it shows (if designed).
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`  `[ ] N/A`
- Saw: ______________________________________________

---

## Phase 3 — Offline reads & persistence (still offline)

### T12 — Browse everything offline
- Do: open Sales, Inventory, Customers, Credits, Reports. Expect: all data (incl. Phase 2) still visible.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T13 — Survive an app restart (offline)  ⭐ key test
- Do: fully close the app (swipe away), reopen **still offline**. Expect: everything from Phase 2 is still there.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

---

## Phase 4 — Reconnect & sync integrity (Airplane mode OFF)

### T14 — Auto-sync on reconnect
- Do: reconnect, wait a few seconds (or reopen). Expect: sync runs **on its own**, no manual action.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T15 — Everything reached the server
- Do: in Supabase, confirm every Phase-2 entry is now there (sale, stock change, credit payment, expense).
- All present? `[ ] Yes  [ ] No`  — missing: __________________
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`

### T16 — Exactly once (no duplicates)  ⭐ key test
- Do: count the synced sale / payment in Supabase. Expect: each appears **once**.
- Any duplicates? `[ ] No  [ ] Yes` — which: __________________
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`

### T17 — Timestamps preserved  ⭐ key test
- Do: check `created_at` of the offline sale in Supabase. Expect: = the time you **made** it (Phase 2), not the sync time.
- Server time shown: __________  vs. made at: __________  — match? `[ ] Yes  [ ] No`
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`

### T18 — Money & stock match
- Do: compare server sale total + resulting stock vs. what the app showed offline.
- Match? `[ ] Yes  [ ] No`
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

---

## Phase 5 — Mixed ordering & math

### T19 — Ordered stock changes (do offline, then sync)
- Do: on ONE product: sell 3 → restock +5 → sell 2. Reconnect.
- Expect: final stock on server is correct for that order.
- Starting stock: ____  Expected final: ____  Server final: ____  — match? `[ ] Yes  [ ] No`
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`

### T20 — Discount + partial credit payment
- Do: sale with a discount + a partial credit payment. Reconnect.
- Expect: server shows correct subtotal, discount, total, remaining balance.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

---

## Phase 6 — Identity / session (online)

### T21 — Sign out / sign in
- Do: sign out, sign back in. Expect: data re-loads correctly; nothing lost or duplicated.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`
- Saw: ______________________________________________

### T22 — Different account isolation (needs a 2nd account)
- Do: sign in as a different user. Expect: you see **that** account's data, not the first's.
- Result: `[ ] Pass`  `[ ] Fail`  `[ ] Skip`  `[ ] N/A`
- Saw: ______________________________________________

---

## Not testable on one device (for awareness)

- **Stock conflicts / oversell** — needs two devices selling the same units offline, then both sync. (Can be forced via the backend if you want to see the resolution screen.)
- **Two-way sync** — seeing another device's changes. Needs a second device.

---

## Summary

- Tests passed: ____ / 22
- **Blocking issues found** (data loss, duplicates, wrong totals, crash):
  1. ______________________________________________
  2. ______________________________________________
- Minor issues / polish:
  1. ______________________________________________
- Verdict: `[ ] Safe to land`   `[ ] Needs fixes first`
