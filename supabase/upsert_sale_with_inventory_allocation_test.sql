-- upsert_sale_with_inventory_allocation_test.sql
-- Manual RPC regression test. Run after migrations, as a privileged DB role.
-- The transaction rolls back all seed data.

begin;

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  'aaaaaaaa-0000-0000-0000-000000000001',
  'authenticated',
  'authenticated',
  'sale-rpc-allocation-test@example.invalid',
  '',
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now()
);

insert into public.profiles (id, full_name)
values ('aaaaaaaa-0000-0000-0000-000000000001', 'Sale RPC Allocation Test');

insert into public.shops (id, owner_id, name)
values (
  'aaaaaaaa-0000-0000-0000-000000000010',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'Sale RPC Allocation Test Shop'
);

insert into public.branches (id, shop_id, name)
values
  (
    'aaaaaaaa-0000-0000-0000-000000000020',
    'aaaaaaaa-0000-0000-0000-000000000010',
    'Main'
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000021',
    'aaaaaaaa-0000-0000-0000-000000000010',
    'Other Branch'
  );

insert into public.products (
  id, shop_id, name, measurement_unit_id, low_stock_threshold, is_active
) values
  (
    'aaaaaaaa-0000-0000-0000-000000000030',
    'aaaaaaaa-0000-0000-0000-000000000010',
    'Tracked Test Product',
    '10000000-0000-0000-0000-000000000001',
    0,
    true
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000031',
    'aaaaaaaa-0000-0000-0000-000000000010',
    'Other Test Product',
    '10000000-0000-0000-0000-000000000001',
    0,
    true
  );

insert into public.product_batches (id, branch_id, product_id, quantity)
values
  (
    'aaaaaaaa-0000-0000-0000-000000000040',
    'aaaaaaaa-0000-0000-0000-000000000020',
    'aaaaaaaa-0000-0000-0000-000000000030',
    10
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000041',
    'aaaaaaaa-0000-0000-0000-000000000021',
    'aaaaaaaa-0000-0000-0000-000000000030',
    10
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000042',
    'aaaaaaaa-0000-0000-0000-000000000020',
    'aaaaaaaa-0000-0000-0000-000000000031',
    10
  );

insert into public.sales (
  id, branch_id, cashier_id, payment_method_id,
  subtotal, discount_amount, total
) values (
  'aaaaaaaa-0000-0000-0000-000000000050',
  'aaaaaaaa-0000-0000-0000-000000000020',
  'aaaaaaaa-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  1,
  0,
  1
);

insert into public.sale_items (
  id, sale_id, product_id, product_name_snapshot,
  measurement_unit_id, quantity, unit_price, discount_amount, total
) values (
  'aaaaaaaa-0000-0000-0000-000000000060',
  'aaaaaaaa-0000-0000-0000-000000000050',
  'aaaaaaaa-0000-0000-0000-000000000030',
  'Tracked Test Product',
  '10000000-0000-0000-0000-000000000001',
  1,
  1,
  0,
  1
);

set local role authenticated;
set local request.jwt.claims to
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
declare
  v_sale jsonb := jsonb_build_object(
    'id', 'aaaaaaaa-0000-0000-0000-000000000100',
    'branch_id', 'aaaaaaaa-0000-0000-0000-000000000020',
    'payment_method_id', '20000000-0000-0000-0000-000000000001'
  );
  v_items jsonb := jsonb_build_array(jsonb_build_object(
    'id', 'aaaaaaaa-0000-0000-0000-000000000110',
    'product_id', 'aaaaaaaa-0000-0000-0000-000000000030',
    'product_name_snapshot', 'Tracked Test Product',
    'measurement_unit_id', '10000000-0000-0000-0000-000000000001',
    'quantity', '2',
    'unit_price', '1',
    'discount_amount', '0'
  ));
begin
  begin
    perform public.upsert_sale_with_inventory(
      v_sale || jsonb_build_object('id', 'aaaaaaaa-0000-0000-0000-000000000105'),
      v_items,
      false,
      null,
      null
    );
    raise exception 'FAIL: wholesale sale without allocations was accepted';
  exception when others then
    if sqlerrm not like 'Wholesale tracked sale items require batch allocations%' then
      raise;
    end if;
  end;

  begin
    perform public.upsert_sale_with_inventory(
      v_sale || jsonb_build_object('id', 'aaaaaaaa-0000-0000-0000-000000000106'),
      v_items,
      false,
      null,
      '[]'::jsonb
    );
    raise exception 'FAIL: wholesale sale with empty allocations was accepted';
  exception when others then
    if sqlerrm not like 'Wholesale tracked sale items require batch allocations%' then
      raise;
    end if;
  end;

  begin
    perform public.upsert_sale_with_inventory(
      v_sale || jsonb_build_object('id', 'aaaaaaaa-0000-0000-0000-000000000107'),
      v_items,
      false,
      null,
      jsonb_build_array(jsonb_build_object(
        'id', 'aaaaaaaa-0000-0000-0000-000000000127',
        'sale_item_id', 'aaaaaaaa-0000-0000-0000-000000000110',
        'batch_id', 'aaaaaaaa-0000-0000-0000-000000000040',
        'quantity', '1'
      ))
    );
    raise exception 'FAIL: partial wholesale allocation was accepted';
  exception when others then
    if sqlerrm not like 'Batch allocation quantity must equal sale item quantity%' then
      raise;
    end if;
  end;

  begin
    perform public.upsert_sale_with_inventory(
      v_sale,
      v_items,
      false,
      null,
      jsonb_build_array(jsonb_build_object(
        'id', 'aaaaaaaa-0000-0000-0000-000000000120',
        'sale_item_id', 'aaaaaaaa-0000-0000-0000-000000000110',
        'batch_id', 'aaaaaaaa-0000-0000-0000-000000000040',
        'quantity', '-1'
      ), jsonb_build_object(
        'id', 'aaaaaaaa-0000-0000-0000-000000000128',
        'sale_item_id', 'aaaaaaaa-0000-0000-0000-000000000110',
        'batch_id', 'aaaaaaaa-0000-0000-0000-000000000040',
        'quantity', '3'
      ))
    );
    raise exception 'FAIL: negative allocation quantity was accepted';
  exception when others then
    if sqlerrm not like 'Invalid batch allocation quantity%' then
      raise;
    end if;
  end;

  begin
    perform public.upsert_sale_with_inventory(
      v_sale || jsonb_build_object('id', 'aaaaaaaa-0000-0000-0000-000000000101'),
      v_items || jsonb_build_array(),
      false,
      null,
      jsonb_build_array(jsonb_build_object(
        'id', 'aaaaaaaa-0000-0000-0000-000000000121',
        'sale_item_id', 'aaaaaaaa-0000-0000-0000-000000000110',
        'batch_id', 'aaaaaaaa-0000-0000-0000-000000000041',
        'quantity', '2'
      ))
    );
    raise exception 'FAIL: allocation from another branch was accepted';
  exception when others then
    if sqlerrm not like 'Invalid batch allocation%' then
      raise;
    end if;
  end;

  begin
    perform public.upsert_sale_with_inventory(
      v_sale || jsonb_build_object('id', 'aaaaaaaa-0000-0000-0000-000000000102'),
      v_items || jsonb_build_array(),
      false,
      null,
      jsonb_build_array(jsonb_build_object(
        'id', 'aaaaaaaa-0000-0000-0000-000000000122',
        'sale_item_id', 'aaaaaaaa-0000-0000-0000-000000000110',
        'batch_id', 'aaaaaaaa-0000-0000-0000-000000000042',
        'quantity', '2'
      ))
    );
    raise exception 'FAIL: allocation from another product was accepted';
  exception when others then
    if sqlerrm not like 'Invalid batch allocation%' then
      raise;
    end if;
  end;

  begin
    perform public.upsert_sale_with_inventory(
      v_sale || jsonb_build_object('id', 'aaaaaaaa-0000-0000-0000-000000000103'),
      v_items || jsonb_build_array(),
      false,
      null,
      jsonb_build_array(jsonb_build_object(
        'id', 'aaaaaaaa-0000-0000-0000-000000000129',
        'sale_item_id', 'aaaaaaaa-0000-0000-0000-000000000110',
        'batch_id', 'aaaaaaaa-0000-0000-0000-000000000040',
        'quantity', '2'
      ), jsonb_build_object(
        'id', 'aaaaaaaa-0000-0000-0000-000000000123',
        'sale_item_id', 'aaaaaaaa-0000-0000-0000-000000000060',
        'batch_id', 'aaaaaaaa-0000-0000-0000-000000000040',
        'quantity', '1'
      ))
    );
    raise exception 'FAIL: allocation for another sale item was accepted';
  exception when others then
    if sqlerrm not like 'Invalid batch allocation%' then
      raise;
    end if;
  end;

  perform public.upsert_sale_with_inventory(
    v_sale || jsonb_build_object('id', 'aaaaaaaa-0000-0000-0000-000000000104'),
    jsonb_build_array(jsonb_build_object(
      'id', 'aaaaaaaa-0000-0000-0000-000000000114',
      'product_id', 'aaaaaaaa-0000-0000-0000-000000000030',
      'product_name_snapshot', 'Tracked Test Product',
      'measurement_unit_id', '10000000-0000-0000-0000-000000000001',
      'quantity', '2',
      'unit_price', '1',
      'discount_amount', '0'
    )),
    false,
    null,
    jsonb_build_array(jsonb_build_object(
      'id', 'aaaaaaaa-0000-0000-0000-000000000124',
      'sale_item_id', 'aaaaaaaa-0000-0000-0000-000000000114',
      'batch_id', 'aaaaaaaa-0000-0000-0000-000000000040',
      'quantity', '2'
    ))
  );

  if not exists (
    select 1
    from public.sale_item_batches
    where id = 'aaaaaaaa-0000-0000-0000-000000000124'
      and sale_item_id = 'aaaaaaaa-0000-0000-0000-000000000114'
      and batch_id = 'aaaaaaaa-0000-0000-0000-000000000040'
      and quantity = 2
  ) then
    raise exception 'FAIL: valid wholesale allocation was not inserted';
  end if;

  raise notice 'PASS: upsert_sale_with_inventory validates batch allocations';
end;
$$;

rollback;
