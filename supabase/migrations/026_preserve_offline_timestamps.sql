-- 026_preserve_offline_timestamps.sql
-- Offline-first v2 — preserve the ORIGINAL recording time of work that was done
-- offline and replayed later.
--
-- Problem: record_credit_payment and apply_inventory_adjustment let the server
-- default created_at to now() at PUSH time. A device may be offline for days
-- (the whole point of offline-first), so a payment recorded Monday but synced
-- Thursday landed with Thursday's date — wrong for the dispute audit trail and
-- the stock-adjustment ledger.
--
-- Fix: both RPCs take an optional p_created_at; the client passes the local
-- row's real created_at. Falls back to now() for the online path (no local
-- row) and for any caller that omits it. (recorded_by / adjusted_by stay
-- auth.uid(): the per-user local DB guarantees the syncing user IS the original
-- actor, so attribution was already correct.)
--
-- Adding a parameter changes the function signature, so the old signatures are
-- dropped first to avoid leaving an ambiguous overload for PostgREST.

drop function if exists public.record_credit_payment(
  uuid, uuid, uuid, numeric, text, text
);

create function public.record_credit_payment(
  p_id uuid,
  p_sale_id uuid,
  p_customer_id uuid,
  p_amount numeric,
  p_method text,
  p_notes text default null,
  p_created_at timestamptz default null
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_shop_id uuid;
  v_sale_customer_id uuid;
  v_sale_total numeric(15,4);
  v_is_credit boolean;
  v_status text;
  v_paid numeric(15,4);
  v_methods integer;
  v_single_method text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_amount <= 0 then
    raise exception 'Payment amount must be positive';
  end if;
  if p_method not in ('cash', 'bank_transfer') then
    raise exception 'Unsupported payment method';
  end if;

  select b.shop_id, s.customer_id, s.total, s.is_credit, s.status
    into v_shop_id, v_sale_customer_id, v_sale_total, v_is_credit, v_status
  from public.sales s
  join public.branches b on b.id = s.branch_id
  where s.id = p_sale_id
  for update of s;

  if v_shop_id is null then
    raise exception 'Sale not found';
  end if;
  if not private.has_permission(v_shop_id, 'customers.manage') then
    raise exception 'Permission denied' using errcode = '42501';
  end if;
  if not v_is_credit or v_status <> 'completed' then
    raise exception 'Sale is not an outstanding credit sale';
  end if;
  if v_sale_customer_id is distinct from p_customer_id then
    raise exception 'Customer does not match the sale';
  end if;

  if not exists (select 1 from public.credit_payments where id = p_id) then
    select coalesce(sum(cp.amount), 0) into v_paid
    from public.credit_payments cp
    where cp.sale_id = p_sale_id;

    if v_paid + p_amount > v_sale_total then
      raise exception 'Payment exceeds the remaining balance';
    end if;

    insert into public.credit_payments (
      id, sale_id, customer_id, amount, method, notes, recorded_by, created_at
    ) values (
      p_id, p_sale_id, p_customer_id, p_amount, p_method,
      nullif(trim(p_notes), ''), auth.uid(), coalesce(p_created_at, now())
    );
  end if;

  select coalesce(sum(cp.amount), 0), count(distinct cp.method), min(cp.method)
    into v_paid, v_methods, v_single_method
  from public.credit_payments cp
  where cp.sale_id = p_sale_id;

  if v_paid >= v_sale_total then
    update public.sales
    set credit_settled_at = coalesce(credit_settled_at, now()),
        credit_settlement_method = case
          when v_methods = 1 then v_single_method
          else null
        end
    where id = p_sale_id;
    return true;
  end if;

  return false;
end;
$$;

revoke all on function public.record_credit_payment(
  uuid, uuid, uuid, numeric, text, text, timestamptz
) from public, anon;
grant execute on function public.record_credit_payment(
  uuid, uuid, uuid, numeric, text, text, timestamptz
) to authenticated;

drop function if exists public.apply_inventory_adjustment(
  uuid, text, uuid, uuid, numeric, numeric, text, date
);

create function public.apply_inventory_adjustment(
  p_id uuid,
  p_type text,
  p_branch_id uuid,
  p_product_id uuid,
  p_quantity_before numeric,
  p_quantity_after numeric,
  p_notes text default null,
  p_expiry_date date default null,
  p_created_at timestamptz default null
)
returns numeric
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_shop_id uuid;
  v_db_type text;
  v_before numeric(15,4);
  v_after numeric(15,4);
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select b.shop_id into v_shop_id
  from public.branches b
  where b.id = p_branch_id;

  if v_shop_id is null then
    raise exception 'Unknown branch';
  end if;

  v_db_type := case when p_type = 'restock' then 'supply_received' else p_type end;
  if v_db_type not in ('opening_stock', 'manual', 'supply_received') then
    raise exception 'Unsupported inventory adjustment type: %', p_type;
  end if;

  if v_db_type = 'manual' then
    if not private.has_permission(v_shop_id, 'settings.manage') then
      raise exception 'Permission denied' using errcode = '42501';
    end if;
  elsif not private.has_permission(v_shop_id, 'inventory.adjust') then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.products p
    where p.id = p_product_id and p.shop_id = v_shop_id
  ) then
    raise exception 'Product does not belong to this shop';
  end if;

  select ia.quantity_after into v_after
  from public.inventory_adjustments ia
  where ia.id = p_id;
  if found then
    return v_after;
  end if;

  insert into public.inventory (branch_id, product_id, quantity, expiry_date)
  values (p_branch_id, p_product_id, 0, p_expiry_date)
  on conflict (branch_id, product_id) do nothing;

  select i.quantity into v_before
  from public.inventory i
  where i.branch_id = p_branch_id and i.product_id = p_product_id
  for update;

  if v_db_type = 'manual' then
    v_after := p_quantity_after;
  else
    v_after := v_before + (p_quantity_after - p_quantity_before);
  end if;

  if v_after < 0 and v_db_type <> 'manual' then
    raise exception 'Inventory adjustment would make stock negative';
  end if;

  insert into public.inventory_adjustments (
    id, branch_id, product_id, adjusted_by, type,
    quantity_before, quantity_after, notes, created_at
  ) values (
    p_id, p_branch_id, p_product_id, auth.uid(), v_db_type,
    v_before, v_after, p_notes, coalesce(p_created_at, now())
  );

  update public.inventory
  set quantity = v_after,
      expiry_date = coalesce(p_expiry_date, expiry_date)
  where branch_id = p_branch_id and product_id = p_product_id;

  return v_after;
end;
$$;

revoke all on function public.apply_inventory_adjustment(
  uuid, text, uuid, uuid, numeric, numeric, text, date, timestamptz
) from public, anon;
grant execute on function public.apply_inventory_adjustment(
  uuid, text, uuid, uuid, numeric, numeric, text, date, timestamptz
) to authenticated;
