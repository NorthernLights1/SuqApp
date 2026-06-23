-- ============================================================
-- 037 — harden upsert_refund_with_inventory (CodeRabbit BLOCK)
-- ============================================================
-- Three BLOCK items from the first pass:
--
-- B1: Validation loop processed each p_items row independently.
--     Two rows for the same sale_item_id could each pass the cap while their
--     combined qty exceeded it. Fix: aggregate by sale_item_id, validate totals.
--
-- B2: RPC trusted client-provided total_amount and item amounts — a caller
--     could record inflated or negative values. Fix: ignore client amounts;
--     compute total_amount and per-item amounts server-side proportionally
--     (sale_items.total * refund_qty / sale_items.quantity).
--
-- B3: Wholesale batch_adjustments were not validated against sale_item_batches.
--     A caller could restock a wrong batch/product or omit adjustments to fall
--     into the retail code path. Fix: validate each adjustment — batch must
--     belong to a refunded sale item (via sale_item_batches), product_id must
--     match the batch, return qty may not exceed what was drawn.
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
  v_adj           jsonb;
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

  -- B1: Aggregate by sale_item_id before validating. Duplicate rows for the
  -- same sale item now sum their quantities before the cap check, so two rows
  -- of qty=1 for a sold-qty=1 item are correctly rejected together.
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

  -- B2: Compute total_amount server-side — proportional to each item's line
  -- total (sale_items.total * refund_qty / sale_items.quantity). The client's
  -- p_refund.total_amount is never used.
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

  -- B2: Per-item amount also computed server-side (proportional).
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

  if p_batch_adjustments is not null
     and jsonb_typeof(p_batch_adjustments) = 'array'
     and jsonb_array_length(p_batch_adjustments) > 0 then
    -- Wholesale: negative adjustments on the original lots.
    for v_adj in select value from jsonb_array_elements(p_batch_adjustments)
    loop
      v_batch_id    := (v_adj->>'batch_id')::uuid;
      v_adj_product := (v_adj->>'product_id')::uuid;
      v_qty         := (v_adj->>'quantity')::numeric;

      if v_qty <= 0 then
        raise exception 'Invalid restock quantity';
      end if;

      -- B3a: product_id must match the batch's actual product.
      if not exists (
        select 1 from public.product_batches pb
        where pb.id = v_batch_id and pb.product_id = v_adj_product
      ) then
        raise exception 'Batch % does not match product %', v_batch_id, v_adj_product;
      end if;

      -- B3b: The batch must have been drawn from one of the refunded sale items.
      select coalesce(sum(sib.quantity), 0) into v_drawn
      from public.sale_item_batches sib
      where sib.batch_id = v_batch_id
        and sib.sale_item_id in (
          select (it->>'sale_item_id')::uuid from jsonb_array_elements(p_items) it
        )
        and sib.deleted_at is null;

      if v_drawn = 0 then
        raise exception 'Batch % was not drawn for any refunded sale item', v_batch_id;
      end if;

      -- B3c: Can't restock more than was drawn from this batch for these items.
      if v_qty > v_drawn then
        raise exception 'Restock qty exceeds drawn qty % for batch %', v_drawn, v_batch_id;
      end if;

      insert into public.batch_adjustments (
        id, batch_id, branch_id, product_id, quantity_delta, reason, created_by
      ) values (
        coalesce(nullif(v_adj->>'id', '')::uuid, gen_random_uuid()),
        v_batch_id, v_branch_id, v_adj_product,
        -v_qty, 'Refund restock', auth.uid()
      );
    end loop;
  else
    -- Retail: derive restock from the lines (product_id via sale_items).
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
