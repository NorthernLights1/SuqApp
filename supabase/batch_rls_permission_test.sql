-- batch_rls_permission_test.sql
-- Manual RLS regression test. Run after migrations, as a privileged DB role.
-- The transaction rolls back all seed data.

begin;

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  'cccccccc-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'batch-rls-owner-test@example.invalid',
  '',
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now()
), (
  'cccccccc-0000-0000-0000-000000000001',
  'authenticated',
  'authenticated',
  'batch-rls-cashier-test@example.invalid',
  '',
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now()
);

insert into public.profiles (id, full_name)
values
  ('cccccccc-0000-0000-0000-000000000000', 'Batch RLS Owner Test'),
  ('cccccccc-0000-0000-0000-000000000001', 'Batch RLS Cashier Test');

insert into public.shops (id, owner_id, name)
values (
  'cccccccc-0000-0000-0000-000000000010',
  'cccccccc-0000-0000-0000-000000000000',
  'Batch RLS Test Shop'
);

insert into public.branches (id, shop_id, name)
values (
  'cccccccc-0000-0000-0000-000000000020',
  'cccccccc-0000-0000-0000-000000000010',
  'Main'
);

insert into public.shop_users (shop_id, branch_id, user_id, role_id, status)
values (
  'cccccccc-0000-0000-0000-000000000010',
  'cccccccc-0000-0000-0000-000000000020',
  'cccccccc-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000003',
  'active'
);

insert into public.shop_settings (shop_id, branch_id, key, value, updated_by)
values (
  'cccccccc-0000-0000-0000-000000000010',
  null,
  'shop_type',
  '"wholesale"'::jsonb,
  'cccccccc-0000-0000-0000-000000000000'
);

insert into public.products (
  id, shop_id, name, measurement_unit_id, low_stock_threshold, is_active
) values (
  'cccccccc-0000-0000-0000-000000000030',
  'cccccccc-0000-0000-0000-000000000010',
  'Batch RLS Product',
  '10000000-0000-0000-0000-000000000001',
  0,
  true
);

insert into public.product_batches (id, branch_id, product_id, batch_number, quantity)
values (
  'cccccccc-0000-0000-0000-000000000040',
  'cccccccc-0000-0000-0000-000000000020',
  'cccccccc-0000-0000-0000-000000000030',
  'RLS-1',
  10
);

insert into public.batch_adjustments (
  id, batch_id, branch_id, product_id, quantity_delta, reason
) values (
  'cccccccc-0000-0000-0000-000000000050',
  'cccccccc-0000-0000-0000-000000000040',
  'cccccccc-0000-0000-0000-000000000020',
  'cccccccc-0000-0000-0000-000000000030',
  1,
  'seed row for direct update/delete checks'
);

set local role authenticated;
set local request.jwt.claims to
  '{"sub":"cccccccc-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
declare
  v_rows int;
begin
  if not private.has_permission(
    'cccccccc-0000-0000-0000-000000000010',
    'sales.create'
  ) or not private.has_permission(
    'cccccccc-0000-0000-0000-000000000010',
    'inventory.view'
  ) or private.has_permission(
    'cccccccc-0000-0000-0000-000000000010',
    'inventory.adjust'
  ) then
    raise exception 'FAIL: test user permissions are not cashier-like';
  end if;

  begin
    insert into public.product_batches (
      id, branch_id, product_id, batch_number, quantity
    ) values (
      'cccccccc-0000-0000-0000-000000000041',
      'cccccccc-0000-0000-0000-000000000020',
      'cccccccc-0000-0000-0000-000000000030',
      'DENIED',
      1
    );
    raise exception 'FAIL: cashier inserted product_batches directly';
  exception when insufficient_privilege then
    null;
  end;

  update public.product_batches
  set quantity = 99
  where id = 'cccccccc-0000-0000-0000-000000000040';
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FAIL: cashier updated product_batches directly';
  end if;

  delete from public.product_batches
  where id = 'cccccccc-0000-0000-0000-000000000040';
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FAIL: cashier deleted product_batches directly';
  end if;

  begin
    insert into public.batch_adjustments (
      id, batch_id, branch_id, product_id, quantity_delta, reason
    ) values (
      'cccccccc-0000-0000-0000-000000000051',
      'cccccccc-0000-0000-0000-000000000040',
      'cccccccc-0000-0000-0000-000000000020',
      'cccccccc-0000-0000-0000-000000000030',
      1,
      'denied'
    );
    raise exception 'FAIL: cashier inserted batch_adjustments directly';
  exception when insufficient_privilege then
    null;
  end;

  update public.batch_adjustments
  set quantity_delta = 9
  where id = 'cccccccc-0000-0000-0000-000000000050';
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FAIL: cashier updated batch_adjustments directly';
  end if;

  delete from public.batch_adjustments
  where id = 'cccccccc-0000-0000-0000-000000000050';
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FAIL: cashier deleted batch_adjustments directly';
  end if;

  perform public.upsert_sale_with_inventory(
    jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-000000000060',
      'branch_id', 'cccccccc-0000-0000-0000-000000000020',
      'payment_method_id', '20000000-0000-0000-0000-000000000001'
    ),
    jsonb_build_array(jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-000000000070',
      'product_id', 'cccccccc-0000-0000-0000-000000000030',
      'product_name_snapshot', 'Batch RLS Product',
      'measurement_unit_id', '10000000-0000-0000-0000-000000000001',
      'quantity', '2',
      'unit_price', '1',
      'discount_amount', '0'
    )),
    false,
    null,
    jsonb_build_array(jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-000000000080',
      'sale_item_id', 'cccccccc-0000-0000-0000-000000000070',
      'batch_id', 'cccccccc-0000-0000-0000-000000000040',
      'quantity', '2'
    ))
  );

  if not exists (
    select 1
    from public.sale_item_batches
    where id = 'cccccccc-0000-0000-0000-000000000080'
  ) then
    raise exception 'FAIL: sale RPC did not insert sale_item_batches';
  end if;

  begin
    insert into public.sale_item_batches (id, sale_item_id, batch_id, quantity)
    values (
      'cccccccc-0000-0000-0000-000000000081',
      'cccccccc-0000-0000-0000-000000000070',
      'cccccccc-0000-0000-0000-000000000040',
      1
    );
    raise exception 'FAIL: cashier inserted sale_item_batches directly';
  exception when insufficient_privilege then
    null;
  end;

  begin
    update public.sale_item_batches
    set quantity = 1
    where id = 'cccccccc-0000-0000-0000-000000000080';
    raise exception 'FAIL: cashier updated sale_item_batches directly';
  exception when insufficient_privilege then
    null;
  end;

  begin
    delete from public.sale_item_batches
    where id = 'cccccccc-0000-0000-0000-000000000080';
    raise exception 'FAIL: cashier deleted sale_item_batches directly';
  exception when insufficient_privilege then
    null;
  end;

  perform public.upsert_refund_with_inventory(
    jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-000000000090',
      'original_sale_id', 'cccccccc-0000-0000-0000-000000000060',
      'branch_id', 'cccccccc-0000-0000-0000-000000000020',
      'reason', 'RLS regression',
      'restock', true
    ),
    jsonb_build_array(jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-000000000091',
      'sale_item_id', 'cccccccc-0000-0000-0000-000000000070',
      'quantity', '1'
    )),
    jsonb_build_array(jsonb_build_object(
      'id', 'cccccccc-0000-0000-0000-000000000092',
      'batch_id', 'cccccccc-0000-0000-0000-000000000040',
      'sale_item_id', 'cccccccc-0000-0000-0000-000000000070',
      'quantity', '1'
    ))
  );

  if not exists (
    select 1
    from public.batch_adjustments
    where id = 'cccccccc-0000-0000-0000-000000000092'
      and quantity_delta = -1
  ) then
    raise exception 'FAIL: refund RPC did not insert batch_adjustments';
  end if;

  raise notice 'PASS: cashier batch table writes are blocked and RPC paths work';
end;
$$;

rollback;
