-- 029_batch_depletion.sql
-- Phase 3: make the batch model offline-correct end to end.
--
-- Supersedes 028's rollup. 028 set inventory.quantity = Σ(batch.quantity),
-- treating a batch's quantity as "current". That double-counts an offline
-- add-then-sell. The correct model (see DECISIONS.md "Batch + expiry tracking"):
--
--   * product_batches.quantity is IMMUTABLE = quantity RECEIVED.
--   * Depletion is recorded ONLY as rows in sale_item_batches (append-only).
--   * remaining(batch)      = received − Σ(its non-deleted sale_item_batches)
--   * inventory.quantity    = Σ(received) − Σ(all non-deleted depletions)
--
-- Every state change is an INSERT (batch received / depletion recorded) or a
-- soft-delete (void) — idempotent by UUID, order-independent, retry-safe.
--
-- Also adds BATCH-LEVEL oversell detection: a specific lot can go negative while
-- the product total stays positive (two phones drawing the last 2 units of a
-- soon-expiring lot), which the product-level detect_stock_conflict (021) misses.
--
-- Idempotent. No-op on current data (no wholesale shops / batches / depletions).

-- ════════════════════════════════════════════════════════════════════════════
-- 1. Batch-aware rollup: inventory.quantity = Σ(received) − Σ(depletions)
-- ════════════════════════════════════════════════════════════════════════════
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
    and sib.deleted_at is null;

  insert into public.inventory (branch_id, product_id, quantity)
  values (p_branch, p_product, v_received - v_depleted)
  on conflict (branch_id, product_id)
    do update set quantity = excluded.quantity;
end;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. Batch-level oversell detection (independent of the product total)
-- ════════════════════════════════════════════════════════════════════════════
alter table public.stock_conflicts
  add column if not exists batch_id uuid references public.product_batches(id) on delete cascade;

-- Open-conflict uniqueness is now per-batch. nulls not distinct keeps retail's
-- one-open-per-product (batch_id null) behaviour intact.
drop index if exists public.stock_conflicts_open_idx;
create unique index stock_conflicts_open_idx
  on public.stock_conflicts (branch_id, product_id, batch_id) nulls not distinct
  where resolved_at is null;

create or replace function public.detect_batch_conflict(p_batch uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_branch    uuid;
  v_product   uuid;
  v_received  numeric(15,4);
  v_depleted  numeric(15,4);
  v_remaining numeric(15,4);
begin
  select b.branch_id, b.product_id, b.quantity
    into v_branch, v_product, v_received
  from public.product_batches b
  where b.id = p_batch;
  if v_branch is null then
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
  end if;
end;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. Triggers — replace 028's sum-only rollup
-- ════════════════════════════════════════════════════════════════════════════
-- product_batches change → recompute the product rollup; a soft-delete that
-- leaves the lot net-negative also raises a batch conflict.
create or replace function public.on_product_batches_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.recompute_product_rollup(
    coalesce(NEW.branch_id, OLD.branch_id),
    coalesce(NEW.product_id, OLD.product_id)
  );
  perform public.detect_batch_conflict(coalesce(NEW.id, OLD.id));
  return null;
end;
$$;

-- sale_item_batches change → recompute the affected lot's product rollup AND
-- run the batch-level conflict check (the part the product total can hide).
create or replace function public.on_sale_item_batches_change()
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

drop trigger if exists trg_product_batches_rollup on public.product_batches;
create trigger trg_product_batches_rollup
  after insert or update or delete on public.product_batches
  for each row execute function public.on_product_batches_change();

create trigger trg_sale_item_batches_rollup
  after insert or update or delete on public.sale_item_batches
  for each row execute function public.on_sale_item_batches_change();

-- 028's sum-only rollup function is now unused.
drop function if exists public.recompute_inventory_rollup();

-- ════════════════════════════════════════════════════════════════════════════
-- 4. Sale RPC — wholesale writes the depletion ledger, not inventory directly
-- ════════════════════════════════════════════════════════════════════════════
-- p_item_batches (nullable): the device's FEFO allocation
--   [{ id, sale_item_id, batch_id, quantity }, …].
-- Present  → wholesale: insert sale_item_batches (idempotent); the trigger
--            maintains the rollup + batch conflicts. NO inventory.quantity write.
-- Absent   → retail: the existing inventory.quantity decrement loop, unchanged.
create or replace function public.upsert_sale_with_inventory(
  p_sale jsonb,
  p_items jsonb,
  p_allow_oversell boolean default false,
  p_discount_reason text default null,
  p_item_batches jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sale_id uuid := (p_sale->>'id')::uuid;
  v_branch_id uuid := (p_sale->>'branch_id')::uuid;
  v_shop_id uuid;
  v_customer_id uuid := nullif(p_sale->>'customer_id', '')::uuid;
  v_payment_method_id uuid := (p_sale->>'payment_method_id')::uuid;
  v_is_credit boolean := coalesce((p_sale->>'is_credit')::boolean, false);
  v_subtotal numeric(15,4) := 0;
  v_discount numeric(15,4) := 0;
  v_total numeric(15,4) := 0;
  v_item jsonb;
  v_alloc jsonb;
  v_item_id uuid;
  v_product_id uuid;
  v_quantity numeric(15,4);
  v_unit_price numeric(15,4);
  v_item_discount numeric(15,4);
  v_inventory_status text;
  v_stock numeric(15,4);
  v_needed numeric(15,4);
  v_already_applied numeric(15,4);
  v_to_apply numeric(15,4);
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select b.shop_id into v_shop_id
  from public.branches b
  where b.id = v_branch_id and b.is_active;

  if v_shop_id is null or not private.has_permission(v_shop_id, 'sales.create') then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'A sale requires at least one item';
  end if;

  if not exists (
    select 1 from public.payment_methods pm
    where pm.id = v_payment_method_id
      and pm.is_active
      and (pm.shop_id is null or pm.shop_id = v_shop_id)
  ) then
    raise exception 'Invalid payment method';
  end if;

  if v_customer_id is not null and not exists (
    select 1 from public.customers c
    where c.id = v_customer_id and c.shop_id = v_shop_id
  ) then
    raise exception 'Customer does not belong to this shop';
  end if;

  if v_is_credit and v_customer_id is null then
    raise exception 'Credit sales require a customer';
  end if;

  if exists (
    select 1 from public.sales s
    where s.id = v_sale_id
      and (s.branch_id <> v_branch_id or s.cashier_id <> auth.uid())
  ) then
    raise exception 'Sale id belongs to a different sale';
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_quantity := (v_item->>'quantity')::numeric;
    v_unit_price := (v_item->>'unit_price')::numeric;
    v_item_discount := coalesce((v_item->>'discount_amount')::numeric, 0);
    v_product_id := nullif(v_item->>'product_id', '')::uuid;

    if v_quantity <= 0 or v_unit_price < 0 or v_item_discount < 0
       or v_item_discount > v_quantity * v_unit_price then
      raise exception 'Invalid sale item values';
    end if;

    if v_product_id is not null and not exists (
      select 1 from public.products p
      where p.id = v_product_id and p.shop_id = v_shop_id and p.is_active
    ) then
      raise exception 'Product does not belong to this shop';
    end if;

    v_subtotal := v_subtotal + (v_quantity * v_unit_price);
    v_discount := v_discount + v_item_discount;
  end loop;
  v_total := v_subtotal - v_discount;

  insert into public.sales (
    id, branch_id, customer_id, cashier_id, payment_method_id,
    subtotal, discount_amount, total, status, is_credit, notes, created_at,
    credit_settled_at, credit_settlement_method
  ) values (
    v_sale_id, v_branch_id, v_customer_id, auth.uid(), v_payment_method_id,
    v_subtotal, v_discount, v_total, 'completed', v_is_credit,
    nullif(p_sale->>'notes', ''),
    coalesce((p_sale->>'created_at')::timestamptz, now()),
    nullif(p_sale->>'credit_settled_at', '')::timestamptz,
    nullif(p_sale->>'credit_settlement_method', '')
  )
  on conflict (id) do update set
    credit_settled_at = coalesce(
      excluded.credit_settled_at, public.sales.credit_settled_at
    ),
    credit_settlement_method = coalesce(
      excluded.credit_settlement_method,
      public.sales.credit_settlement_method
    );

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_item_id := coalesce(nullif(v_item->>'id', '')::uuid, gen_random_uuid());
    v_product_id := nullif(v_item->>'product_id', '')::uuid;
    v_quantity := (v_item->>'quantity')::numeric;
    v_unit_price := (v_item->>'unit_price')::numeric;
    v_item_discount := coalesce((v_item->>'discount_amount')::numeric, 0);
    v_inventory_status := coalesce(
      nullif(v_item->>'inventory_status', ''),
      case when v_product_id is null then 'untracked' else 'tracked' end
    );

    insert into public.sale_items (
      id, sale_id, product_id, product_name_snapshot,
      measurement_unit_id, quantity, unit_price, discount_amount, total,
      inventory_status, cost_price_snapshot
    ) values (
      v_item_id,
      v_sale_id,
      v_product_id,
      v_item->>'product_name_snapshot',
      nullif(v_item->>'measurement_unit_id', '')::uuid,
      v_quantity,
      v_unit_price,
      v_item_discount,
      (v_quantity * v_unit_price) - v_item_discount,
      v_inventory_status,
      nullif(v_item->>'cost_price_snapshot', '')::numeric
    )
    on conflict (id) do nothing;

    if p_discount_reason is not null and v_item_discount > 0
       and not exists (
         select 1 from public.discounts d where d.sale_item_id = v_item_id
       ) then
      insert into public.discounts (
        sale_id, sale_item_id, given_by, type, value, reason
      ) values (
        v_sale_id, v_item_id, auth.uid(), 'fixed',
        v_item_discount, p_discount_reason
      );
    end if;
  end loop;

  -- ── Stock depletion ─────────────────────────────────────────────────────────
  if p_item_batches is not null and jsonb_typeof(p_item_batches) = 'array'
     and jsonb_array_length(p_item_batches) > 0 then
    -- WHOLESALE: record the FEFO depletions. The sale_item_batches trigger
    -- recomputes the rollup and runs batch-level conflict detection. Idempotent
    -- by allocation id, so a re-push never double-depletes. (Oversell is allowed
    -- here regardless of p_allow_oversell — the conflict surfaces it.)
    for v_alloc in select value from jsonb_array_elements(p_item_batches)
    loop
      insert into public.sale_item_batches (id, sale_item_id, batch_id, quantity)
      values (
        (v_alloc->>'id')::uuid,
        (v_alloc->>'sale_item_id')::uuid,
        (v_alloc->>'batch_id')::uuid,
        (v_alloc->>'quantity')::numeric
      )
      on conflict (id) do nothing;
    end loop;
  else
    -- RETAIL: unchanged direct inventory.quantity decrement.
    for v_product_id, v_needed in
      select si.product_id, sum(si.quantity)
      from public.sale_items si
      where si.sale_id = v_sale_id
        and si.product_id is not null
        and si.inventory_status <> 'untracked'
      group by si.product_id
      order by si.product_id
    loop
      select coalesce(sum(ia.quantity_before - ia.quantity_after), 0)
        into v_already_applied
      from public.inventory_adjustments ia
      where ia.reference_id = v_sale_id
        and ia.reference_type = 'sale'
        and ia.product_id = v_product_id
        and ia.type = 'sale';

      v_to_apply := v_needed - v_already_applied;
      if v_to_apply <= 0 then
        continue;
      end if;

      insert into public.inventory (branch_id, product_id, quantity)
      values (v_branch_id, v_product_id, 0)
      on conflict (branch_id, product_id) do nothing;

      select i.quantity into v_stock
      from public.inventory i
      where i.branch_id = v_branch_id and i.product_id = v_product_id
      for update;

      if not p_allow_oversell and v_stock < v_to_apply then
        raise exception 'Insufficient stock for product %', v_product_id;
      end if;

      insert into public.inventory_adjustments (
        branch_id, product_id, adjusted_by, type,
        quantity_before, quantity_after, reference_id, reference_type
      ) values (
        v_branch_id, v_product_id, auth.uid(), 'sale',
        v_stock, v_stock - v_to_apply, v_sale_id, 'sale'
      );

      update public.inventory
      set quantity = v_stock - v_to_apply
      where branch_id = v_branch_id and product_id = v_product_id;
    end loop;
  end if;

  return v_sale_id;
end;
$$;

revoke all on function public.upsert_sale_with_inventory(
  jsonb, jsonb, boolean, text, jsonb
) from public, anon;
grant execute on function public.upsert_sale_with_inventory(
  jsonb, jsonb, boolean, text, jsonb
) to authenticated;

-- ════════════════════════════════════════════════════════════════════════════
-- 5. Void RPC — wholesale reverses depletions via soft-delete
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.void_sale_with_inventory(
  p_sale_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_branch_id uuid;
  v_shop_id uuid;
  v_status text;
  v_product_id uuid;
  v_quantity numeric(15,4);
  v_stock numeric(15,4);
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select s.branch_id, b.shop_id, s.status
    into v_branch_id, v_shop_id, v_status
  from public.sales s
  join public.branches b on b.id = s.branch_id
  where s.id = p_sale_id
  for update of s;

  if v_branch_id is null then
    raise exception 'Sale not found';
  end if;
  if not private.has_permission(v_shop_id, 'sales.void') then
    raise exception 'Permission denied' using errcode = '42501';
  end if;
  if v_status = 'voided' then
    return;
  end if;
  if v_status <> 'completed' then
    raise exception 'Only completed sales can be voided';
  end if;
  if nullif(trim(p_reason), '') is null then
    raise exception 'Void reason is required';
  end if;

  if exists (
    select 1 from public.sale_item_batches sib
    join public.sale_items si on si.id = sib.sale_item_id
    where si.sale_id = p_sale_id and sib.deleted_at is null
  ) then
    -- WHOLESALE: reverse the depletions; the trigger restores the rollup to the
    -- exact batches the sale drew from.
    update public.sale_item_batches sib
    set deleted_at = now()
    from public.sale_items si
    where si.id = sib.sale_item_id
      and si.sale_id = p_sale_id
      and sib.deleted_at is null;
  else
    -- RETAIL: unchanged add-back to inventory.quantity.
    for v_product_id, v_quantity in
      select si.product_id, sum(si.quantity)
      from public.sale_items si
      where si.sale_id = p_sale_id
        and si.product_id is not null
        and si.inventory_status <> 'untracked'
      group by si.product_id
      order by si.product_id
    loop
      insert into public.inventory (branch_id, product_id, quantity)
      values (v_branch_id, v_product_id, 0)
      on conflict (branch_id, product_id) do nothing;

      select i.quantity into v_stock
      from public.inventory i
      where i.branch_id = v_branch_id and i.product_id = v_product_id
      for update;

      insert into public.inventory_adjustments (
        branch_id, product_id, adjusted_by, type,
        quantity_before, quantity_after, reference_id, reference_type, notes
      ) values (
        v_branch_id, v_product_id, auth.uid(), 'void',
        v_stock, v_stock + v_quantity, p_sale_id, 'sale_void', p_reason
      );

      update public.inventory
      set quantity = v_stock + v_quantity
      where branch_id = v_branch_id and product_id = v_product_id;
    end loop;
  end if;

  update public.sales
  set status = 'voided',
      void_reason = trim(p_reason),
      voided_by = auth.uid(),
      voided_at = now()
  where id = p_sale_id;
end;
$$;

revoke all on function public.void_sale_with_inventory(uuid, text)
  from public, anon;
grant execute on function public.void_sale_with_inventory(uuid, text)
  to authenticated;
