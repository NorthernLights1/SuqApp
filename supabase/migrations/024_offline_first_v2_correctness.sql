-- Offline-first v2 correctness and authorization fixes.

-- These columns are used by the application but were missing from the
-- reproducible migration history.
alter table public.products
  add column if not exists cost_price numeric(15,4);

alter table public.sale_items
  add column if not exists cost_price_snapshot numeric(15,4);

-- Credit is a first-class system payment method on a fresh deployment.
insert into public.payment_methods
  (id, shop_id, name, code, is_active, is_system)
select
  '20000000-0000-0000-0000-000000000003', null, 'Credit', 'credit', true, true
where not exists (
  select 1 from public.payment_methods where code = 'credit'
)
on conflict (id) do update set
  name = excluded.name,
  code = excluded.code,
  is_active = excluded.is_active,
  is_system = excluded.is_system;

-- PostgreSQL's regular UNIQUE constraint treats NULL branch ids as distinct.
-- Keep the most recently updated duplicate, then enforce shop-wide uniqueness.
with ranked as (
  select id,
         row_number() over (
           partition by shop_id, branch_id, key
           order by updated_at desc, id desc
         ) as row_number
  from public.shop_settings
)
delete from public.shop_settings s
using ranked r
where s.id = r.id and r.row_number > 1;

alter table public.shop_settings
  drop constraint if exists shop_settings_shop_id_branch_id_key_key;

drop index if exists public.shop_settings_scope_key_uidx;
create unique index shop_settings_scope_key_uidx
  on public.shop_settings (shop_id, branch_id, key) nulls not distinct;

-- Central permission check used by RLS and transactional RPCs. Shop owners are
-- allowed even if a legacy onboarding attempt failed before creating shop_users.
create or replace function private.has_permission(
  p_shop_id uuid,
  p_permission_code text
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select auth.uid() is not null and (
    exists (
      select 1
      from public.shops s
      where s.id = p_shop_id and s.owner_id = auth.uid()
    )
    or exists (
      select 1
      from public.shop_users su
      join public.role_permissions rp on rp.role_id = su.role_id
      join public.permissions p on p.id = rp.permission_id
      where su.shop_id = p_shop_id
        and su.user_id = auth.uid()
        and su.status = 'active'
        and p.code = p_permission_code
    )
  );
$$;

revoke all on function private.has_permission(uuid, text) from public, anon;
grant execute on function private.has_permission(uuid, text) to authenticated;

-- Apply one queued inventory operation under a row lock. The ledger entry and
-- quantity update commit together, and the client-generated id makes retries
-- idempotent.
create or replace function public.apply_inventory_adjustment(
  p_id uuid,
  p_type text,
  p_branch_id uuid,
  p_product_id uuid,
  p_quantity_before numeric,
  p_quantity_after numeric,
  p_notes text default null,
  p_expiry_date date default null
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
    quantity_before, quantity_after, notes
  ) values (
    p_id, p_branch_id, p_product_id, auth.uid(), v_db_type,
    v_before, v_after, p_notes
  );

  update public.inventory
  set quantity = v_after,
      expiry_date = coalesce(p_expiry_date, expiry_date)
  where branch_id = p_branch_id and product_id = p_product_id;

  return v_after;
end;
$$;

revoke all on function public.apply_inventory_adjustment(
  uuid, text, uuid, uuid, numeric, numeric, text, date
) from public, anon;
grant execute on function public.apply_inventory_adjustment(
  uuid, text, uuid, uuid, numeric, numeric, text, date
) to authenticated;

-- Create or retry a sale atomically with its items and stock deduction. Online
-- checkout rejects insufficient stock; an offline replay may oversell so the
-- stock-conflict trigger can surface the real reconciliation work.
create or replace function public.upsert_sale_with_inventory(
  p_sale jsonb,
  p_items jsonb,
  p_allow_oversell boolean default false,
  p_discount_reason text default null
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

  return v_sale_id;
end;
$$;

revoke all on function public.upsert_sale_with_inventory(
  jsonb, jsonb, boolean, text
) from public, anon;
grant execute on function public.upsert_sale_with_inventory(
  jsonb, jsonb, boolean, text
) to authenticated;

-- Void and stock restoration are one transaction. The branch comes from the
-- sale, so a different active branch in the UI cannot receive the stock.
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
      quantity_before, quantity_after, reference_id, reference_type,
      notes
    ) values (
      v_branch_id, v_product_id, auth.uid(), 'void',
      v_stock, v_stock + v_quantity, p_sale_id, 'sale_void', p_reason
    );

    update public.inventory
    set quantity = v_stock + v_quantity
    where branch_id = v_branch_id and product_id = v_product_id;
  end loop;

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

-- Record a credit installment and settle the bill under one sale-row lock.
-- The caller supplies an id so offline retries cannot duplicate a payment.
create or replace function public.record_credit_payment(
  p_id uuid,
  p_sale_id uuid,
  p_customer_id uuid,
  p_amount numeric,
  p_method text,
  p_notes text default null
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
      id, sale_id, customer_id, amount, method, notes, recorded_by
    ) values (
      p_id, p_sale_id, p_customer_id, p_amount, p_method,
      nullif(trim(p_notes), ''), auth.uid()
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
  uuid, uuid, uuid, numeric, text, text
) from public, anon;
grant execute on function public.record_credit_payment(
  uuid, uuid, uuid, numeric, text, text
) to authenticated;

-- Onboarding RPCs prevent half-created shops/branches on transient failures.
create or replace function public.create_shop_with_owner(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_shop_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if nullif(trim(p_name), '') is null then
    raise exception 'Shop name is required';
  end if;

  insert into public.shops (owner_id, name)
  values (auth.uid(), trim(p_name))
  returning id into v_shop_id;

  insert into public.shop_users (shop_id, user_id, role_id, status)
  values (
    v_shop_id,
    auth.uid(),
    '00000000-0000-0000-0000-000000000001',
    'active'
  );

  return v_shop_id;
end;
$$;

revoke all on function public.create_shop_with_owner(text) from public, anon;
grant execute on function public.create_shop_with_owner(text) to authenticated;

create or replace function public.create_branch_with_defaults(
  p_shop_id uuid,
  p_name text,
  p_address text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_branch_id uuid;
begin
  if not private.has_permission(p_shop_id, 'settings.manage') then
    raise exception 'Permission denied' using errcode = '42501';
  end if;
  if nullif(trim(p_name), '') is null then
    raise exception 'Branch name is required';
  end if;

  insert into public.branches (shop_id, name, address)
  values (p_shop_id, trim(p_name), nullif(trim(p_address), ''))
  returning id into v_branch_id;

  insert into public.shop_settings (
    shop_id, branch_id, key, value, updated_by
  ) values
    (p_shop_id, null, 'inventory_mode', to_jsonb('strict'::text), auth.uid()),
    (p_shop_id, null, 'sync_warning_hours', to_jsonb(12), auth.uid()),
    (p_shop_id, null, 'low_stock_notify', to_jsonb(true), auth.uid()),
    (p_shop_id, null, 'currency_code', to_jsonb('ETB'::text), auth.uid()),
    (p_shop_id, null, 'locale', to_jsonb('en'::text), auth.uid())
  on conflict (shop_id, branch_id, key) do nothing;

  return v_branch_id;
end;
$$;

revoke all on function public.create_branch_with_defaults(uuid, text, text)
  from public, anon;
grant execute on function public.create_branch_with_defaults(uuid, text, text)
  to authenticated;

-- Enforce the same RBAC model on writes. Read policies stay broad where the
-- checkout and sync engines need shared reference data.
drop policy if exists branches_write on public.branches;
create policy branches_write on public.branches for all
  using (private.has_permission(shop_id, 'settings.manage'))
  with check (private.has_permission(shop_id, 'settings.manage'));

drop policy if exists product_categories_write on public.product_categories;
create policy product_categories_write on public.product_categories for all
  using (private.has_permission(shop_id, 'inventory.edit'))
  with check (private.has_permission(shop_id, 'inventory.edit'));

drop policy if exists products_write on public.products;
create policy products_write on public.products for all
  using (private.has_permission(shop_id, 'inventory.edit'))
  with check (private.has_permission(shop_id, 'inventory.edit'));

-- Inventory and its ledger are only writable through the atomic RPC above.
drop policy if exists inventory_write on public.inventory;

drop policy if exists inventory_adjustments_insert
  on public.inventory_adjustments;

drop policy if exists customers_write on public.customers;
create policy customers_write on public.customers for all
  using (private.has_permission(shop_id, 'customers.manage'))
  with check (private.has_permission(shop_id, 'customers.manage'));

drop policy if exists expenses_write on public.expenses;
create policy expenses_write on public.expenses for all
  using (private.has_permission(
    private.shop_id_from_branch(branch_id), 'expenses.manage'
  ))
  with check (private.has_permission(
    private.shop_id_from_branch(branch_id), 'expenses.manage'
  ));

drop policy if exists shop_settings_write on public.shop_settings;
create policy shop_settings_write on public.shop_settings for all
  using (private.has_permission(shop_id, 'settings.manage'))
  with check (private.has_permission(shop_id, 'settings.manage'));

drop policy if exists payment_methods_write on public.payment_methods;
create policy payment_methods_write on public.payment_methods for all
  using (shop_id is not null and private.has_permission(shop_id, 'settings.manage'))
  with check (shop_id is not null and private.has_permission(shop_id, 'settings.manage'));

drop policy if exists measurement_units_write on public.measurement_units;
create policy measurement_units_write on public.measurement_units for all
  using (shop_id is not null and private.has_permission(shop_id, 'inventory.edit'))
  with check (shop_id is not null and private.has_permission(shop_id, 'inventory.edit'));

drop policy if exists expense_categories_write on public.expense_categories;
create policy expense_categories_write on public.expense_categories for all
  using (shop_id is not null and private.has_permission(shop_id, 'expenses.manage'))
  with check (shop_id is not null and private.has_permission(shop_id, 'expenses.manage'));

drop policy if exists suppliers_write on public.suppliers;
create policy suppliers_write on public.suppliers for all
  using (private.has_permission(shop_id, 'supplies.manage'))
  with check (private.has_permission(shop_id, 'supplies.manage'));

drop policy if exists supply_orders_write on public.supply_orders;
create policy supply_orders_write on public.supply_orders for all
  using (private.has_permission(
    private.shop_id_from_branch(branch_id), 'supplies.manage'
  ))
  with check (private.has_permission(
    private.shop_id_from_branch(branch_id), 'supplies.manage'
  ));

drop policy if exists supply_order_items_write on public.supply_order_items;
create policy supply_order_items_write on public.supply_order_items for all
  using (exists (
    select 1 from public.supply_orders so
    where so.id = supply_order_id
      and private.has_permission(
        private.shop_id_from_branch(so.branch_id), 'supplies.manage'
      )
  ))
  with check (exists (
    select 1 from public.supply_orders so
    where so.id = supply_order_id
      and private.has_permission(
        private.shop_id_from_branch(so.branch_id), 'supplies.manage'
      )
  ));

drop policy if exists cash_reconciliations_write
  on public.cash_reconciliations;
create policy cash_reconciliations_write on public.cash_reconciliations for all
  using (private.has_permission(
    private.shop_id_from_branch(branch_id), 'reconciliation.manage'
  ))
  with check (private.has_permission(
    private.shop_id_from_branch(branch_id), 'reconciliation.manage'
  ));

drop policy if exists export_jobs_write on public.export_jobs;
create policy export_jobs_write on public.export_jobs for all
  using (private.has_permission(shop_id, 'reports.export'))
  with check (private.has_permission(shop_id, 'reports.export'));

drop policy if exists notification_configs_write on public.notification_configs;
create policy notification_configs_write on public.notification_configs for all
  using (private.has_permission(shop_id, 'settings.manage'))
  with check (private.has_permission(shop_id, 'settings.manage'));

drop policy if exists shop_users_write on public.shop_users;
create policy shop_users_write on public.shop_users for all
  using (private.has_permission(shop_id, 'staff.manage'))
  with check (private.has_permission(shop_id, 'staff.manage'));

drop policy if exists shop_users_select on public.shop_users;
create policy shop_users_select on public.shop_users for select
  using (
    user_id = auth.uid()
    or private.has_permission(shop_id, 'staff.view')
  );

drop policy if exists sales_insert on public.sales;

drop policy if exists sales_update on public.sales;

drop policy if exists sale_items_insert on public.sale_items;

drop policy if exists discounts_insert on public.discounts;

drop policy if exists credit_payments_insert on public.credit_payments;

drop policy if exists refunds_insert on public.refunds;
create policy refunds_insert on public.refunds for insert
  with check (refunded_by = auth.uid() and exists (
    select 1 from public.sales s
    where s.id = original_sale_id
      and (
        private.has_permission(
          private.shop_id_from_branch(s.branch_id), 'sales.refund_any'
        )
        or (
          s.cashier_id = auth.uid()
          and private.has_permission(
            private.shop_id_from_branch(s.branch_id), 'sales.refund_own'
          )
        )
      )
  ));

drop policy if exists refund_items_insert on public.refund_items;
create policy refund_items_insert on public.refund_items for insert
  with check (exists (
    select 1
    from public.refunds r
    join public.sales s on s.id = r.original_sale_id
    where r.id = refund_id
      and r.refunded_by = auth.uid()
      and (
        private.has_permission(
          private.shop_id_from_branch(s.branch_id), 'sales.refund_any'
        )
        or (
          s.cashier_id = auth.uid()
          and private.has_permission(
            private.shop_id_from_branch(s.branch_id), 'sales.refund_own'
          )
        )
      )
  ));
