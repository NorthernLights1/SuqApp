-- 023_offline_sync_metadata.sql
-- Offline-first v2, Phase A — sync metadata foundation.
-- See docs/ai-context/DECISIONS.md "Offline-first v2".
--
-- Adds the two columns the delta-sync engine depends on to every REPLICA table
-- (the shop tables the device mirrors locally — NOT admin/operator tables):
--   * updated_at  — server-set "row last changed" cursor for delta pull
--   * deleted_at  — soft-delete tombstone so deletions propagate on pull
--
-- WHY updated_at is server-set (trigger), never trusted from the device:
--   Delta pull asks "give me rows where updated_at > my cursor". If the device
--   set updated_at, a wrong device clock could hide rows or let stale data win a
--   last-write-wins merge. The trigger stamps now() on INSERT *and* UPDATE.
--
-- WHY the trigger fires on INSERT too (not just UPDATE):
--   A sale created offline 3 days ago and pushed today must get updated_at =
--   today. If it kept the offline creation time, another device whose cursor is
--   from yesterday would never pull it (3-days-ago < yesterday). updated_at =
--   "when the server received this", which is exactly what delta pull needs.
--   (created_at still holds the true creation time — the two are decoupled.)
--
-- Admin/operator tables are intentionally absent: license_keys, shop_controls,
-- notification_*, export_jobs, sync_logs, roles/permissions, suppliers/supply_*,
-- cash_reconciliations. The device never replicates these (RLS denies them and
-- license status is fetched via a narrow RPC — see Phase B).
--
-- Applied manually via the Supabase SQL editor (project convention, see
-- DECISIONS.md "SQL migrations run manually"). Idempotent — safe to re-run.

-- ── Shared trigger function ──────────────────────────────────────────────────
-- Plain (not SECURITY DEFINER): it only assigns NEW.updated_at, touches no
-- tables, runs as the caller. search_path pinned empty as hygiene.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ── Apply columns + trigger + delta index to every replica table ─────────────
do $$
declare
  t text;
  replica_tables text[] := array[
    'shops',
    'branches',
    'shop_settings',
    'payment_methods',
    'product_categories',
    'measurement_units',
    'products',
    'inventory',
    'inventory_adjustments',
    'sales',
    'sale_items',
    'customers',
    'expenses',
    'expense_categories',
    'credit_payments',
    'profiles'
  ];
begin
  foreach t in array replica_tables loop
    -- updated_at: skip if the table already has it (inventory, shop_settings).
    -- Backfills existing rows to now() so the first post-migration delta pull
    -- re-sends everything once (harmless; devices start from a null cursor).
    execute format(
      'alter table public.%I add column if not exists updated_at timestamptz not null default now()', t);

    -- deleted_at: soft-delete tombstone. Null = live row.
    execute format(
      'alter table public.%I add column if not exists deleted_at timestamptz', t);

    -- Server-authoritative updated_at on INSERT and UPDATE.
    -- All identifiers (trigger name + table) quoted via %I.
    execute format(
      'create or replace trigger %I before insert or update on public.%I '
      'for each row execute function public.set_updated_at()',
      'trg_' || t || '_set_updated_at', t);

    -- Delta-pull index: "rows changed since cursor".
    execute format(
      'create index if not exists %I on public.%I (updated_at)',
      'idx_' || t || '_updated_at', t);
  end loop;
end;
$$;

-- ── Notes for Phase B (pull engine) ──────────────────────────────────────────
-- * Pull query per table: where updated_at > :cursor (include deleted_at rows so
--   the device learns of deletions, then hard-deletes them locally).
-- * Going forward, NEVER hard-delete a replica row from the app — set
--   deleted_at = now() instead, or the deletion can't propagate via delta.
-- * Consider composite (shop_id, updated_at) indexes once pull queries are
--   written, for tables with a direct shop_id (products, customers, etc.).
