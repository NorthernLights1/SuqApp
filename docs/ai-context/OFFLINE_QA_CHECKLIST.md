# Offline-First Device Shakedown — QA Checklist

Branch: `offline-first` | Covers Phases A–C (delta sync engine + the five offline
bug fixes + single-boundary writes). Run before merging `offline-first` → `main`.

Each item is **action → expected**. Tick `[x]` as you pass them; note failures
inline.

---

## 0. Setup
- [ ] Build the APK from `offline-first` (GitHub Actions workflow).
- [ ] Two devices logged into the **same shop** (owner on both, or owner + an
  invited staff member). The web app counts as a second device.
- [ ] "Offline" = **airplane mode**. "Online / trigger sync" = airplane mode off
  (sync nudges within ~2s, or on app reopen).
- [ ] Internalize: offline reads are **"as of last sync"** — another device's
  changes appear after a sync, not instantly. By design.

---

## 1. Regression — the five reported bugs (all should be FIXED)
- [ ] Offline → New Sale → **payment methods load** (Cash/Bank), no error.
- [ ] Offline → Inventory → add/edit product → **categories load**, no error.
- [ ] Offline → Credits → settle a bill (full or partial) → **succeeds**.
- [ ] Offline → Credits → a credit sale → Details → **customer name + "Sold by"
  cashier both show**.
- [ ] Offline → all of the above → **feels as fast as online** (no multi-second hangs).

---

## 2. Offline writes, single device (write offline → reconnect → on the server)
Do offline, confirm local, then reconnect and verify on device 2 after a sync:
- [ ] New cash **sale**.
- [ ] New **credit sale** with a customer.
- [ ] **Settle** a credit bill (partial, then the rest).
- [ ] Record an **expense**.
- [ ] **Add stock** and **Correct stock** on a product.
- [ ] **Add a customer** and **edit** a customer's name/phone.

---

## 3. Offline reads, single device (every screen works with no connection)
- [ ] Offline, each loads with data: **Dashboard/Today, Sales list, Inventory,
  Customers, Credits, Expenses, Reports (incl. drill-downs), Settings**.

---

## 4. Sync timing & speed
- [ ] **First login on a fresh device** → one-time fuller download (a few seconds
  with lots of history); afterward syncs are quick (delta).
- [ ] Online: make a sale → within ~2s it reaches the server (verify on device 2).
- [ ] **Flaky-signal test** (the original "faster online" symptom): on a weak
  connection the app still feels instant — NOT slower than airplane mode. Key
  regression to confirm gone.

---

## 5. App lifecycle / crash resilience
- [ ] Make 2–3 sales **offline**, **force-kill** the app before reconnecting →
  reopen → sales still there → reconnect → they sync.
- [ ] Settle a bill offline → force-kill before reconnect → reopen → settlement
  persisted → syncs.
- [ ] Kill the app **mid-sync** (reconnect then immediately kill) → reopen → no
  duplicates, no lost rows on either device.

---

## 6. Multi-device sync (two devices, same shop)
- [ ] A makes a sale → B shows it after a sync (reopen B or wait).
- [ ] A edits a customer's name → B reflects it after sync.
- [ ] A adds stock to a product → B shows the new quantity after sync.
- [ ] A deactivates/deletes a product → B stops showing it after sync.

---

## 7. Multi-device CONFLICTS (force the race: both offline FIRST, act on both, THEN reconnect)
- [ ] **Oversell:** product has **1 unit**. Both devices offline. Sell that unit
  on A *and* B. Reconnect both. → Both sales kept, stock can go **negative**, and
  the **owner gets a stock-conflict alert** (email + in-app **Stock Conflicts**
  screen). Resolve it there.
- [ ] **Concurrent credit settlement:** one unpaid bill. Both offline. Record a
  payment on A and on B for the same bill. Reconnect. → **Both payments survive**
  in the payment history (no money lost); bill ends settled.
- [ ] **Concurrent customer edit:** both offline, both rename the same customer
  differently → reconnect → last sync wins; no crash, no duplicate.

---

## 8. Propagation correctness
- [ ] **Deactivation:** deactivate a product on A → after sync, B (and its sale
  screen) no longer offers it.
- [ ] **Settlement propagation:** settle a bill offline on A → reconnect → on B
  the sale flips to **"Paid"** and drops out of the Credits list.

---

## 9. Schema migration (protects existing testers)
- [ ] If a device has an **older build**, **install the new build over it** (don't
  uninstall) → app opens, **existing local data intact**, no crash. (Verifies the
  v6→v9 local migrations.)

---

## 10. Security — cross-shop isolation (SQL)
- [ ] Run `supabase/rls_isolation_test.sql` **Part 2** with **two accounts from
  different shops** → expect the **PASS** notice (a shop-B user sees zero of
  shop-A's rows). The wall that matters since the app key ships in the APK.

---

## 11. Licensing sanity (offline work shouldn't disturb it)
- [ ] Trial countdown, serial activation, and the blocked-shop lock screen still
  behave. Offline, the app **fails open** — a blip must not lock a legit shop out.

---

## Notes / failures found
(Record here as you go: item #, device, what happened.)

---
*Related: [[INDEX]] · [[OPEN_TASKS]] · [[CURRENT_STATE]] · [[BUGS_AND_FIXES]]*
