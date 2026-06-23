-- ============================================================
-- 040 — harden upsert_refund_with_inventory (CodeRabbit B1-B2)
-- ============================================================
-- B1: RPC was inserting batch_adjustments with gen_random_uuid(), ignoring the
--   client-provided id in p_batch_adjustments. Offline refunds create local rows
--   with known IDs that SyncService sends; if the server mints new IDs the pull
--   inserts duplicate rows and double-counts the negative adjustment (stock bloat).
--   Fix: insert each original p_batch_adjustments row with its own client-provided
--   id. Aggregation is used only for validation, not for insertion.
--
-- B2: Per-batch validation checked restock qty ≤ drawn qty per batch but did not
--   verify that total batch restock equals total refunded qty. A caller could refund
--   2 units and send batch_adjustments for 10 (if 10 were drawn), inflating stock.
--   Fix: before the per-batch loop, assert that restock qty by product equals
--   refunded qty by product (full-outer-join mismatch raises an exception).
alter table public.batch_adjustments
  add column if not exists refund_id uuid references public.refunds(id),
  add column if not exists sale_item_id uuid references public.sale_items(id);

create index if not exists idx_batch_adjustments_refund_sale_item_batch
  on public.batch_adjustments (sale_item_id, batch_id)
  where refund_id is not null and deleted_at is null;

create or replace function public.upsert_refund_with_inventory(
  p_refund jsonb,
  p_items jsonb,
  p_batch_adjustments jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_refund_id     uuid     := (p_refund->>'id')::uuid;
  v_sale_id       uuid     := (p_refund->>'original_sale_id')::uuid;
  v_branch_id     uuid     := (p_refund->>'branch_id')::uuid;
  v_restock       boolean  := coalesce((p_refund->>'restock')::boolean, false);
  v_shop_id       uuid;
  v_sale_branch   uuid;
  v_sale_cashier  uuid;
  v_item          jsonb;
  v_sale_item_id  uuid;
  v_qty           numeric(15,4);
  v_sold          numeric(15,4);
  v_prior         numeric(15,4);
  v_product_id    uuid;
  v_before        numeric(15,4);
  v_total_amount  numeric(15,4);
  v_batch_id      uuid;
  v_adj_product   uuid;
  v_drawn         numeric(15,4);
  v_adj_sale_item_id uuid;
  v_is_wholesale  boolean;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  -- Resolve sale → shop, branch, cashier.
  select s.branch_id, s.cashier_id, b.shop_id
    into v_sale_branch, v_sale_cashier, v_shop_id
  from public.sales s
  join public.branches b on b.id = s.branch_id
  where s.id = v_sale_id;

  if v_shop_id is null then
    raise exception 'Original sale not found';
  end if;
  if v_branch_id is distinct from v_sale_branch then
    raise exception 'Refund branch does not match the sale';
  end if;

  if not (private.has_permission(v_shop_id, 'sales.refund_any')
          or (private.has_permission(v_shop_id, 'sales.refund_own')
              and v_sale_cashier = auth.uid())) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  -- Idempotent: already recorded.
  if exists (select 1 from public.refunds where id = v_refund_id) then
    return v_refund_id;
  end if;

  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'A refund requires at least one item';
  end if;

  -- B1 (from 037): aggregate by sale_item_id before cap check.
  for v_sale_item_id, v_qty in
    select (it->>'sale_item_id')::uuid,
           sum((it->>'quantity')::numeric)
    from jsonb_array_elements(p_items) it
    group by 1
  loop
    if v_qty <= 0 then
      raise exception 'Invalid refund quantity';
    end if;

    select si.quantity into v_sold
    from public.sale_items si
    where si.id = v_sale_item_id and si.sale_id = v_sale_id
    for update;

    if v_sold is null then
      raise exception 'Refund item does not belong to the sale';
    end if;

    select coalesce(sum(ri.quantity), 0) into v_prior
    from public.refund_items ri
    join public.refunds r on r.id = ri.refund_id
    where ri.sale_item_id = v_sale_item_id
      and r.deleted_at is null and ri.deleted_at is null;

    if v_prior + v_qty > v_sold then
      raise exception 'Refund exceeds quantity sold for item %', v_sale_item_id;
    end if;
  end loop;

  -- B2 (from 037): compute total_amount server-side — proportional.
  select coalesce(
    sum(si.total * agg.qty / nullif(si.quantity, 0)), 0
  )
  into v_total_amount
  from (
    select (it->>'sale_item_id')::uuid as sale_item_id,
           sum((it->>'quantity')::numeric) as qty
    from jsonb_array_elements(p_items) it
    group by 1
  ) agg
  join public.sale_items si on si.id = agg.sale_item_id;

  insert into public.refunds (
    id, original_sale_id, branch_id, refunded_by, reason, total_amount,
    restock, created_at
  ) values (
    v_refund_id, v_sale_id, v_branch_id, auth.uid(),
    coalesce(p_refund->>'reason', ''), v_total_amount, v_restock,
    coalesce((p_refund->>'created_at')::timestamptz, now())
  );

  -- B2 (from 037): per-item amount computed server-side.
  for v_item in select value from jsonb_array_elements(p_items)
  loop
    insert into public.refund_items (id, refund_id, sale_item_id, quantity, amount)
    select
      coalesce(nullif(v_item->>'id', '')::uuid, gen_random_uuid()),
      v_refund_id,
      si.id,
      (v_item->>'quantity')::numeric,
      si.total * (v_item->>'quantity')::numeric / nullif(si.quantity, 0)
    from public.sale_items si
    where si.id = (v_item->>'sale_item_id')::uuid;
  end loop;

  if not v_restock then
    return v_refund_id;
  end if;

  -- B4: Detect server-side whether the original sale was wholesale (had
  -- sale_item_batches depletions). Prevents a buggy client from bypassing lot-
  -- level tracking by omitting p_batch_adjustments for a wholesale sale.
  select exists (
    select 1 from public.sale_item_batches sib
    join public.sale_items si on si.id = sib.sale_item_id
    where si.sale_id = v_sale_id and sib.deleted_at is null
  ) into v_is_wholesale;

  if v_is_wholesale then
    if p_batch_adjustments is null
       or jsonb_typeof(p_batch_adjustments) <> 'array'
       or jsonb_array_length(p_batch_adjustments) = 0 then
      raise exception 'Wholesale refund requires batch_adjustments';
    end if;

    -- Each original row must add stock back. Aggregates can hide a bad row
    -- such as +5 and -3, so reject non-positive quantities before summing.
    if exists (
      select 1
      from jsonb_array_elements(p_batch_adjustments) adj
      where (adj->>'quantity')::numeric <= 0
         or nullif(adj->>'sale_item_id', '') is null
    ) then
      raise exception 'Invalid restock quantity';
    end if;

    -- B2 (this migration): assert restock qty by sale item + product equals
    -- refunded qty by sale item + product. Guards against a caller refunding N
    -- units while restocking M>N by targeting a batch with a large drawn qty, or
    -- moving restock quantity between two refunded lines for the same product.
    if exists (
      with restock_by_item as (
        select (adj->>'sale_item_id')::uuid as sale_item_id,
               pb.product_id,
               sum((adj->>'quantity')::numeric) as qty
        from jsonb_array_elements(p_batch_adjustments) adj
        join public.product_batches pb on pb.id = (adj->>'batch_id')::uuid
        group by (adj->>'sale_item_id')::uuid, pb.product_id
      ),
      refund_by_item as (
        select si.id as sale_item_id,
               si.product_id,
               sum((it->>'quantity')::numeric) as qty
        from jsonb_array_elements(p_items) it
        join public.sale_items si on si.id = (it->>'sale_item_id')::uuid
        where si.product_id is not null
        group by si.id, si.product_id
      )
      select 1
      from restock_by_item r
      full outer join refund_by_item f
        on f.sale_item_id = r.sale_item_id
       and f.product_id = r.product_id
      where coalesce(r.qty, 0) <> coalesce(f.qty, 0)
    ) then
      raise exception 'Batch restock quantity must equal refunded quantity per sale item and product';
    end if;

    -- Validation pass: aggregate by sale_item_id + batch_id to check drawn-qty cap.
    -- Aggregation is for validation only — insertion uses original rows below.
    for v_adj_sale_item_id, v_batch_id, v_qty in
      select (adj->>'sale_item_id')::uuid,
             (adj->>'batch_id')::uuid,
             sum((adj->>'quantity')::numeric)
      from jsonb_array_elements(p_batch_adjustments) adj
      group by (adj->>'sale_item_id')::uuid, (adj->>'batch_id')::uuid
    loop
      if v_qty <= 0 then
        raise exception 'Invalid restock quantity';
      end if;

      select pb.product_id into v_adj_product
      from public.product_batches pb
      where pb.id = v_batch_id;

      if v_adj_product is null then
        raise exception 'Batch % not found', v_batch_id;
      end if;

      if not exists (
        select 1
        from jsonb_array_elements(p_items) it
        where (it->>'sale_item_id')::uuid = v_adj_sale_item_id
      ) then
        raise exception 'Batch restock sale item % is not being refunded', v_adj_sale_item_id;
      end if;

      -- Batch must have been drawn for this refunded sale item.
      select coalesce(sum(sib.quantity), 0) into v_drawn
      from public.sale_item_batches sib
      where sib.batch_id = v_batch_id
        and sib.sale_item_id = v_adj_sale_item_id
        and sib.deleted_at is null;

      if v_drawn = 0 then
        raise exception 'Batch % was not drawn for refunded sale item %', v_batch_id, v_adj_sale_item_id;
      end if;

      select coalesce(sum(-ba.quantity_delta), 0) into v_prior
      from public.batch_adjustments ba
      where ba.sale_item_id = v_adj_sale_item_id
        and ba.batch_id = v_batch_id
        and ba.refund_id is not null
        and ba.quantity_delta < 0
        and ba.deleted_at is null;

      -- Combined restock qty may not exceed drawn qty.
      if v_prior + v_qty > v_drawn then
        raise exception 'Restock qty exceeds drawn qty % for sale item % batch %', v_drawn, v_adj_sale_item_id, v_batch_id;
      end if;
    end loop;

    -- B1 (this migration): insert each original row with its own client-provided id.
    -- Two client rows for the same batch_id each get their own server row so both
    -- local UUIDs reconcile on the next pull instead of one dangling.
    for v_item in select value from jsonb_array_elements(p_batch_adjustments)
    loop
      v_batch_id := (v_item->>'batch_id')::uuid;

      select pb.product_id into v_adj_product
      from public.product_batches pb
      where pb.id = v_batch_id;

      insert into public.batch_adjustments (
        id, batch_id, branch_id, product_id, quantity_delta, reason, created_by,
        refund_id, sale_item_id
      ) values (
        coalesce(nullif(v_item->>'id', '')::uuid, gen_random_uuid()),
        v_batch_id, v_branch_id, v_adj_product,
        -(v_item->>'quantity')::numeric, 'Refund restock', auth.uid(),
        v_refund_id, (v_item->>'sale_item_id')::uuid
      );
    end loop;
  else
    -- Retail: derive restock from the lines.
    for v_product_id, v_qty in
      select si.product_id, sum((it->>'quantity')::numeric)
      from jsonb_array_elements(p_items) it
      join public.sale_items si on si.id = (it->>'sale_item_id')::uuid
      where si.product_id is not null
      group by si.product_id
    loop
      insert into public.inventory (branch_id, product_id, quantity)
      values (v_branch_id, v_product_id, 0)
      on conflict (branch_id, product_id) do nothing;

      select quantity into v_before from public.inventory
      where branch_id = v_branch_id and product_id = v_product_id
      for update;

      insert into public.inventory_adjustments (
        branch_id, product_id, adjusted_by, type,
        quantity_before, quantity_after, notes
      ) values (
        v_branch_id, v_product_id, auth.uid(), 'refund',
        v_before, v_before + v_qty, 'Refund restock'
      );

      update public.inventory set quantity = v_before + v_qty
      where branch_id = v_branch_id and product_id = v_product_id;
    end loop;
  end if;

  return v_refund_id;
end;
$$;

revoke all on function public.upsert_refund_with_inventory(jsonb, jsonb, jsonb)
  from public, anon;
grant execute on function public.upsert_refund_with_inventory(jsonb, jsonb, jsonb)
  to authenticated;
