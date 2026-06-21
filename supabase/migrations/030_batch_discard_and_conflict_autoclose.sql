-- 030_batch_discard_and_conflict_autoclose.sql
-- Phase 4 completion: safe lot discard + close the batch-conflict loop.
--
-- 1. DISCARD A LOT = soft-delete the product_batches row (deleted_at). For that
--    to remove EXACTLY the lot's remaining (received − sold), the rollup's
--    depletion sum must also ignore a deleted lot's depletions — otherwise a
--    partially-sold lot's past sales would keep subtracting after the received
--    is gone, driving the rollup too low. 029 missed the `b.deleted_at is null`
--    filter on the depletion side; this adds it (rollup + detector).
--
-- 2. CONFLICT AUTO-CLOSE: detect_batch_conflict now also RESOLVES an open
--    batch conflict when the lot's remaining recovers to >= 0 (the owner added
--    the missing stock) or the lot is discarded. Detection alone (029) could
--    open a conflict but never close it.
--
-- Idempotent. No-op on current data.

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
begin
  select coalesce(sum(b.quantity), 0) into v_received
  from public.product_batches b
  where b.branch_id = p_branch and b.product_id = p_product
    and b.deleted_at is null;

  select coalesce(sum(sib.quantity), 0) into v_depleted
  from public.sale_item_batches sib
  join public.product_batches b on b.id = sib.batch_id
  where b.branch_id = p_branch and b.product_id = p_product
    and b.deleted_at is null            -- ignore discarded lots' depletions
    and sib.deleted_at is null;

  insert into public.inventory (branch_id, product_id, quantity)
  values (p_branch, p_product, v_received - v_depleted)
  on conflict (branch_id, product_id)
    do update set quantity = excluded.quantity;
end;
$$;

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
  v_remaining numeric(15,4);
begin
  select b.branch_id, b.product_id, b.quantity, b.deleted_at
    into v_branch, v_product, v_received, v_deleted
  from public.product_batches b
  where b.id = p_batch;
  if v_branch is null then
    return;
  end if;

  -- A discarded lot can't be in conflict — close any open one and stop.
  if v_deleted is not null then
    update public.stock_conflicts
    set resolved_at = now(), resolution_note = 'auto: lot discarded'
    where batch_id = p_batch and resolved_at is null;
    return;
  end if;

  select coalesce(sum(sib.quantity), 0) into v_depleted
  from public.sale_item_batches sib
  where sib.batch_id = p_batch and sib.deleted_at is null;

  v_remaining := v_received - v_depleted;
  if v_remaining < 0 then
    insert into public.stock_conflicts (branch_id, product_id, batch_id, observed_quantity)
    values (v_branch, v_product, p_batch, v_remaining)
    on conflict (branch_id, product_id, batch_id) where resolved_at is null
      do update set observed_quantity = excluded.observed_quantity,
                    detected_at = now();
  else
    -- Remaining recovered (e.g. the owner added the missing stock) → auto-close.
    update public.stock_conflicts
    set resolved_at = now(), resolution_note = 'auto: stock recovered'
    where batch_id = p_batch and resolved_at is null;
  end if;
end;
$$;
