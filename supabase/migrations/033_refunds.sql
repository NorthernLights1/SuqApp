-- ============================================================
-- 033 — Refunds (offline-first, partial, optional restock)
-- ============================================================
-- The refunds / refund_items tables exist since 003 but were never used. This
-- migration wires them into the offline-first replica model so refunds can be
-- recorded on a device (online or offline), pushed as idempotent upserts, and
-- delta-pulled back like every other replica table.
--
-- Design decisions (2026-06-22, with Temesgen):
--   * Partial: a refund returns specific quantities of specific sale_items.
--     refund_items.quantity holds the returned units; remaining-refundable per
--     line = original qty − Σ already-refunded qty (computed app-side).
--   * Optional restock per refund (refunds.restock). When true, the goods go
--     back to stock — but the stock effect does NOT live here: it rides the
--     EXISTING idempotent ledgers, so no new restock RPC is needed:
--        - retail   → an additive inventory_adjustments row recorded as type
--          'restock' (apply_inventory_adjustment only accepts opening_stock/
--          manual/supply_received; 'restock' takes the additive supply_received
--          path. The note "Refund restock" marks intent.)
--        - wholesale → negative batch_adjustments against the original lots
--     Both already push offline-first and recompute inventory.quantity.
--   * Any completed sale, anytime. Over-refund is rejected at the repository
--     mutation boundary (existing + requested > sold) on both the native and
--     web paths, in addition to the UI cap.
--
-- The original sale's status is intentionally left 'completed' on a partial
-- refund — "refunded" would misrepresent a sale that's only partly returned,
-- and the refund_items rows already carry the full picture.

-- branch_id: denormalized so the delta pull can scope refunds to the device's
-- branch without joining through original_sale_id every time (parity with how
-- sales are pulled). Nullable: the table is empty today and the device always
-- sets it on insert.
alter table refunds add column if not exists branch_id uuid references branches(id);

-- Did this refund return goods to stock? (false = money-only; goods kept out,
-- e.g. damaged.) The restock ledger rows reference this refund's reason text.
alter table refunds add column if not exists restock boolean not null default false;

-- ── Offline sync metadata (mirror of 023 for these two tables) ───────────────
do $$
declare
  t text;
  refund_tables text[] := array['refunds', 'refund_items'];
begin
  foreach t in array refund_tables loop
    execute format(
      'alter table public.%I add column if not exists updated_at timestamptz not null default now()', t);
    execute format(
      'alter table public.%I add column if not exists deleted_at timestamptz', t);
    execute format(
      'create or replace trigger %I before insert or update on public.%I '
      'for each row execute function public.set_updated_at()',
      'trg_' || t || '_set_updated_at', t);
    execute format(
      'create index if not exists %I on public.%I (updated_at)',
      'idx_' || t || '_updated_at', t);
  end loop;
end;
$$;

-- Authenticated clients read refund history directly for refund caps and
-- offline delta pulls; RLS still scopes which rows are visible.
grant select on public.refunds, public.refund_items to authenticated;
