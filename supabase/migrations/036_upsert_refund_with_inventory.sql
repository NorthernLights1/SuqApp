-- ============================================================
-- 036 — upsert_refund_with_inventory (atomic refund + restock)
-- ============================================================
-- Mirrors upsert_sale_with_inventory: a single SECURITY DEFINER, idempotent,
-- transactional entry point so a refund's financial record (refund + items) and
-- its stock effect (restock) commit together or not at all. Replaces the prior
-- multi-call push (separate refunds/refund_items upserts + ledger pushes), which
-- could leave partial state on a mid-sequence failure (CodeRabbit B2/B5).
--
-- Idempotent by refund id (re-push after a committed call is a no-op). The
-- caller generates all ids; wholesale batch-adjustment ids are reused so the
-- device's optimistic rows reconcile with the server's by id on the next pull.
--
-- Over-refund is enforced HERE at the server boundary (B3): for each line it
-- locks the sale_item and sums existing non-deleted refunds, rejecting when
-- existing + requested exceeds the quantity sold.
--
-- Restock representation:
--   * wholesale → p_batch_adjustments: negative batch_adjustments on the lots
--     the line drew from (the on_batch_adjustments_change trigger recomputes the
--     inventory rollup).
--   * retail → derived from the refunded lines (product_id via sale_items): one
--     additive inventory_adjustments row of type 'refund' per product + an
--     inventory bump. (No p_batch_adjustments ⇒ retail.)
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
  v_refund_id uuid := (p_refund->>'id')::uuid;
  v_sale_id uuid := (p_refund->>'original_sale_id')::uuid;
  v_branch_id uuid := (p_refund->>'branch_id')::uuid;
  v_restock boolean := coalesce((p_refund->>'restock')::boolean, false);
  v_total numeric(15,4) := coalesce((p_refund->>'total_amount')::numeric, 0);
  v_shop_id uuid;
  v_sale_branch uuid;
  v_sale_cashier uuid;
  v_item jsonb;
  v_adj jsonb;
  v_sale_item_id uuid;
  v_qty numeric(15,4);
  v_sold numeric(15,4);
  v_prior numeric(15,4);
  v_product_id uuid;
  v_before numeric(15,4);
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  -- Resolve the original sale → shop, branch, cashier.
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

  -- Permission: refund_any, or refund_own on a sale you rang up.
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

  -- Validate each line against remaining-refundable (lock the sale_item).
  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_sale_item_id := (v_item->>'sale_item_id')::uuid;
    v_qty := (v_item->>'quantity')::numeric;
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
      raise exception 'Refund exceeds quantity sold for an item';
    end if;
  end loop;

  -- Financial record.
  insert into public.refunds (
    id, original_sale_id, branch_id, refunded_by, reason, total_amount,
    restock, created_at
  ) values (
    v_refund_id, v_sale_id, v_branch_id, auth.uid(),
    coalesce(p_refund->>'reason', ''), v_total, v_restock,
    coalesce((p_refund->>'created_at')::timestamptz, now())
  );

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    insert into public.refund_items (id, refund_id, sale_item_id, quantity, amount)
    values (
      coalesce(nullif(v_item->>'id', '')::uuid, gen_random_uuid()),
      v_refund_id,
      (v_item->>'sale_item_id')::uuid,
      (v_item->>'quantity')::numeric,
      coalesce((v_item->>'amount')::numeric, 0)
    );
  end loop;

  if not v_restock then
    return v_refund_id;
  end if;

  if p_batch_adjustments is not null
     and jsonb_typeof(p_batch_adjustments) = 'array'
     and jsonb_array_length(p_batch_adjustments) > 0 then
    -- Wholesale: negative adjustments on the original lots (ids reused from the
    -- device so its optimistic rows reconcile on pull). Trigger recomputes rollup.
    for v_adj in select value from jsonb_array_elements(p_batch_adjustments)
    loop
      v_qty := (v_adj->>'quantity')::numeric;
      if v_qty <= 0 then
        raise exception 'Invalid restock quantity';
      end if;
      insert into public.batch_adjustments (
        id, batch_id, branch_id, product_id, quantity_delta, reason, created_by
      ) values (
        coalesce(nullif(v_adj->>'id', '')::uuid, gen_random_uuid()),
        (v_adj->>'batch_id')::uuid, v_branch_id, (v_adj->>'product_id')::uuid,
        -v_qty, 'Refund restock', auth.uid()
      );
    end loop;
  else
    -- Retail: add returned units back per product (derived from the lines).
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
