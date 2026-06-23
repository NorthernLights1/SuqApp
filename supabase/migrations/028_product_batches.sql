-- 028_product_batches.sql
-- Wholesale batch + expiry tracking (Phase 1 — schema foundation only).
-- See docs/ai-context/DECISIONS.md "Batch + expiry tracking".
--
-- WHY: a wholesaler/pharma distributor holds the same product in multiple
-- batches with different expiry dates. The existing inventory model is ONE
-- quantity + ONE expiry per (branch, product) — it can't represent that.
--
-- MODEL: product_batches holds qty/expiry/batch_number per batch.
-- inventory.quantity becomes a CACHED ROLLUP = sum(non-deleted batch qty).
-- Every existing read (stock list, low-stock, reports, sale pre-check) keeps
-- reading inventory.quantity and is UNCHANGED. Only add-stock (writes a batch)
-- and sale depletion (FEFO across batches) change — that work is Phase 2/3.
--
-- RETAIL IS UNTOUCHED: batches are backfilled and used for WHOLESALE shops only
-- (shop_settings.shop_type = '"wholesale"'). Retail shops get no batches; their
-- inventory.quantity stays directly authoritative (the rollup trigger only ever
-- fires for rows that have batches, i.e. wholesale).
--
-- BONUS: the existing detect_stock_conflict trigger (021) fires on
-- inventory.quantity changes, so routing the rollup through inventory.quantity
-- gives offline oversell detection for batches for free.
--
-- Applied manually via the Supabase SQL editor (project convention). Idempotent.

-- ── product_batches ──────────────────────────────────────────────────────────
create table if not exists product_batches (
  id            uuid primary key default gen_random_uuid(),
  branch_id     uuid not null references branches(id) on delete cascade,
  product_id    uuid not null references products(id) on delete cascade,
  batch_number  text,                                  -- nullable (unlabelled stock)
  expiry_date   date,                                  -- nullable (non-perishable)
  quantity      numeric(15,4) not null default 0,
  cost_price    numeric(15,4),                         -- per-batch landed cost
  received_at   timestamptz not null default now(),
  updated_at    timestamptz not null default now(),    -- server-set (sync cursor)
  deleted_at    timestamptz                            -- soft delete (sync tombstone)
);

-- FEFO scan: soonest-expiry first within a product at a branch.
create index if not exists idx_product_batches_fefo
  on product_batches (branch_id, product_id, expiry_date);
create index if not exists idx_product_batches_updated_at
  on product_batches (updated_at);

-- ── sale_item_batches (recall traceability) ──────────────────────────────────
-- Records how much of each sale line came from each batch, so "which customers
-- received batch X" is answerable. Written during a sale (Phase 3); created now
-- so the schema is stable. Push-only from the device (server-side recall report).
create table if not exists sale_item_batches (
  id            uuid primary key default gen_random_uuid(),
  sale_item_id  uuid not null references sale_items(id) on delete cascade,
  batch_id      uuid not null references product_batches(id),
  quantity      numeric(15,4) not null,
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);
create index if not exists idx_sale_item_batches_batch on sale_item_batches (batch_id);
create index if not exists idx_sale_item_batches_item  on sale_item_batches (sale_item_id);
create index if not exists idx_sale_item_batches_updated_at on sale_item_batches (updated_at);

-- ── Server-set updated_at (reuse the shared trigger fn from 023) ──────────────
create or replace trigger trg_product_batches_set_updated_at
  before insert or update on product_batches
  for each row execute function public.set_updated_at();

create or replace trigger trg_sale_item_batches_set_updated_at
  before insert or update on sale_item_batches
  for each row execute function public.set_updated_at();

-- ── Rollup: inventory.quantity = sum(non-deleted batch quantities) ───────────
-- SECURITY DEFINER so it can write inventory regardless of caller RLS. Only
-- fires for products that HAVE batches (wholesale), so retail is unaffected.
create or replace function public.recompute_inventory_rollup()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_branch  uuid := coalesce(NEW.branch_id, OLD.branch_id);
  v_product uuid := coalesce(NEW.product_id, OLD.product_id);
  v_total   numeric(15,4);
begin
  select coalesce(sum(quantity), 0) into v_total
  from product_batches
  where branch_id = v_branch and product_id = v_product and deleted_at is null;

  insert into inventory (branch_id, product_id, quantity)
  values (v_branch, v_product, v_total)
  on conflict (branch_id, product_id) do update set quantity = excluded.quantity;

  return null;
end;
$$;

create or replace trigger trg_product_batches_rollup
  after insert or update or delete on product_batches
  for each row execute function public.recompute_inventory_rollup();

-- ── RLS ──────────────────────────────────────────────────────────────────────
alter table product_batches   enable row level security;
alter table sale_item_batches enable row level security;

create policy "product_batches_select" on product_batches for select
  to authenticated
  using (private.is_shop_member(private.shop_id_from_branch(branch_id)));
create policy "product_batches_write" on product_batches for all
  to authenticated
  using (private.has_permission(
    private.shop_id_from_branch(branch_id), 'inventory.adjust'
  ))
  with check (private.has_permission(
    private.shop_id_from_branch(branch_id), 'inventory.adjust'
  ));

create policy "sale_item_batches_select" on sale_item_batches for select
  to authenticated
  using (exists (
    select 1 from sale_items si join sales s on s.id = si.sale_id
    where si.id = sale_item_id
      and private.is_shop_member(private.shop_id_from_branch(s.branch_id))));

grant select, insert, update, delete on product_batches   to authenticated;
grant select, insert, update, delete on product_batches   to service_role;
revoke insert, update, delete on sale_item_batches from authenticated;
grant select on sale_item_batches to authenticated;
grant select, insert, update, delete on sale_item_batches to service_role;

-- ── Backfill (WHOLESALE shops only) ──────────────────────────────────────────
-- Each existing inventory row for a wholesale shop becomes one batch carrying
-- its current quantity + expiry. After this the rollup equals today's quantity,
-- so nothing visibly changes. Guarded by NOT EXISTS so re-running is a no-op
-- (idempotent — never double-counts).
insert into product_batches (branch_id, product_id, quantity, expiry_date, batch_number)
select i.branch_id, i.product_id, i.quantity, i.expiry_date, null
from inventory i
join branches b      on b.id = i.branch_id
join shop_settings ss on ss.shop_id = b.shop_id
                     and ss.key = 'shop_type'
                     and ss.value = '"wholesale"'
where not exists (
  select 1 from product_batches pb
  where pb.branch_id = i.branch_id and pb.product_id = i.product_id
);

-- ── Phase 2/3 notes (NOT in this migration) ──────────────────────────────────
-- * Add-stock RPC (apply_inventory_adjustment): for wholesale, write a batch
--   (the rollup trigger updates inventory.quantity) instead of writing inventory
--   directly. Derive wholesale vs retail from shop_type server-side.
-- * Sale RPC (upsert_sale_with_inventory): for wholesale, deplete batches FEFO
--   (expiry asc, nulls last), spilling across batches; insert sale_item_batches
--   rows; the rollup trigger maintains inventory.quantity (and oversell
--   detection fires if a batch/rollup goes negative). Retail path unchanged.
