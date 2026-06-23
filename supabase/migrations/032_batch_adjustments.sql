-- 032_batch_adjustments.sql
-- Per-lot stock CORRECTION (miscount / partial damage of a single lot) as an
-- append-only ledger, mirroring the depletion model. A correction records the
-- quantity removed (positive delta) or added back (negative) from one batch,
-- with a reason and author. Append-only + soft-delete = offline-safe.
--
--   remaining(batch)  = received − Σ(sale_item_batches) − Σ(batch_adjustments)
--   inventory.quantity = Σ(received) − Σ(depletions) − Σ(adjustments)
--
-- The rollup + batch-conflict functions (last set in 030) gain the adjustment
-- term; everything else in them (deleted-lot filters, conflict auto-close) is
-- preserved. Idempotent. No-op on current data.

-- ── Ledger table ─────────────────────────────────────────────────────────────
create table if not exists batch_adjustments (
  id             uuid primary key default gen_random_uuid(),
  batch_id       uuid not null references product_batches(id),
  branch_id      uuid not null references branches(id) on delete cascade,
  product_id     uuid not null references products(id) on delete cascade,
  quantity_delta numeric(15,4) not null,   -- removed (+) / added back (−)
  reason         text,
  created_by     uuid,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz
);
create index if not exists idx_batch_adjustments_batch on batch_adjustments (batch_id);
create index if not exists idx_batch_adjustments_updated_at on batch_adjustments (updated_at);

create or replace trigger trg_batch_adjustments_set_updated_at
  before insert or update on batch_adjustments
  for each row execute function public.set_updated_at();

-- ── Rollup: inventory = Σ(received) − Σ(depletions) − Σ(adjustments) ─────────
create or replace function public.recompute_product_rollup(
  p_branch uuid,
  p_product uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_received numeric(15,4);
  v_depleted numeric(15,4);
  v_adjusted numeric(15,4);
begin
  select coalesce(sum(b.quantity), 0) into v_received
  from public.product_batches b
  where b.branch_id = p_branch and b.product_id = p_product
    and b.deleted_at is null;

  select coalesce(sum(sib.quantity), 0) into v_depleted
  from public.sale_item_batches sib
  join public.product_batches b on b.id = sib.batch_id
  where b.branch_id = p_branch and b.product_id = p_product
    and b.deleted_at is null
    and sib.deleted_at is null;

  select coalesce(sum(ba.quantity_delta), 0) into v_adjusted
  from public.batch_adjustments ba
  join public.product_batches b on b.id = ba.batch_id
  where b.branch_id = p_branch and b.product_id = p_product
    and b.deleted_at is null
    and ba.deleted_at is null;

  insert into public.inventory (branch_id, product_id, quantity)
  values (p_branch, p_product, v_received - v_depleted - v_adjusted)
  on conflict (branch_id, product_id)
    do update set quantity = excluded.quantity;
end;
$$;

-- ── Batch conflict: remaining = received − depletions − adjustments ──────────
create or replace function public.detect_batch_conflict(p_batch uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_branch    uuid;
  v_product   uuid;
  v_deleted   timestamptz;
  v_received  numeric(15,4);
  v_depleted  numeric(15,4);
  v_adjusted  numeric(15,4);
  v_remaining numeric(15,4);
begin
  select b.branch_id, b.product_id, b.quantity, b.deleted_at
    into v_branch, v_product, v_received, v_deleted
  from public.product_batches b
  where b.id = p_batch;
  if v_branch is null then
    return;
  end if;

  if v_deleted is not null then
    update public.stock_conflicts
    set resolved_at = now(), resolution_note = 'auto: lot discarded'
    where batch_id = p_batch and resolved_at is null;
    return;
  end if;

  select coalesce(sum(sib.quantity), 0) into v_depleted
  from public.sale_item_batches sib
  where sib.batch_id = p_batch and sib.deleted_at is null;

  select coalesce(sum(ba.quantity_delta), 0) into v_adjusted
  from public.batch_adjustments ba
  where ba.batch_id = p_batch and ba.deleted_at is null;

  v_remaining := v_received - v_depleted - v_adjusted;
  if v_remaining < 0 then
    insert into public.stock_conflicts (branch_id, product_id, batch_id, observed_quantity)
    values (v_branch, v_product, p_batch, v_remaining)
    on conflict (branch_id, product_id, batch_id) where resolved_at is null
      do update set observed_quantity = excluded.observed_quantity,
                    detected_at = now();
  else
    update public.stock_conflicts
    set resolved_at = now(), resolution_note = 'auto: stock recovered'
    where batch_id = p_batch and resolved_at is null;
  end if;
end;
$$;

-- ── Trigger: an adjustment recomputes the rollup + re-checks the lot ─────────
create or replace function public.on_batch_adjustments_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_batch   uuid := coalesce(NEW.batch_id, OLD.batch_id);
  v_branch  uuid;
  v_product uuid;
begin
  select branch_id, product_id into v_branch, v_product
  from public.product_batches where id = v_batch;
  if v_branch is not null then
    perform public.recompute_product_rollup(v_branch, v_product);
  end if;
  perform public.detect_batch_conflict(v_batch);
  return null;
end;
$$;

drop trigger if exists trg_batch_adjustments_rollup on public.batch_adjustments;
create trigger trg_batch_adjustments_rollup
  after insert or update or delete on public.batch_adjustments
  for each row execute function public.on_batch_adjustments_change();

-- ── RLS ──────────────────────────────────────────────────────────────────────
alter table batch_adjustments enable row level security;
create policy "batch_adjustments_select" on batch_adjustments for select
  to authenticated
  using (private.is_shop_member(private.shop_id_from_branch(branch_id)));
create policy "batch_adjustments_write" on batch_adjustments for all
  to authenticated
  using (private.has_permission(
    private.shop_id_from_branch(branch_id), 'inventory.adjust'
  ))
  with check (private.has_permission(
    private.shop_id_from_branch(branch_id), 'inventory.adjust'
  ));

grant select, insert, update, delete on batch_adjustments to authenticated;
grant select, insert, update, delete on batch_adjustments to service_role;
