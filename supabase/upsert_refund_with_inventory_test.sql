-- upsert_refund_with_inventory_test.sql
-- Manual RPC regression test. Run after migrations, as a privileged DB role.
-- The transaction rolls back all seed data.

begin;

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'authenticated',
  'authenticated',
  'refund-rpc-test@example.invalid',
  '',
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now()
);

insert into public.profiles (id, full_name)
values ('bbbbbbbb-0000-0000-0000-000000000001', 'Refund RPC Test');

insert into public.shops (id, owner_id, name)
values (
  'bbbbbbbb-0000-0000-0000-000000000010',
  'bbbbbbbb-0000-0000-0000-000000000001',
  'Refund RPC Test Shop'
);

insert into public.branches (id, shop_id, name)
values (
  'bbbbbbbb-0000-0000-0000-000000000020',
  'bbbbbbbb-0000-0000-0000-000000000010',
  'Main'
);

insert into public.products (
  id, shop_id, name, measurement_unit_id, low_stock_threshold, is_active
) values
  (
    'bbbbbbbb-0000-0000-0000-000000000030',
    'bbbbbbbb-0000-0000-0000-000000000010',
    'Refund Product A',
    '10000000-0000-0000-0000-000000000001',
    0,
    true
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000031',
    'bbbbbbbb-0000-0000-0000-000000000010',
    'Refund Product B',
    '10000000-0000-0000-0000-000000000001',
    0,
    true
  );

insert into public.product_batches (id, branch_id, product_id, batch_number, quantity)
values
  (
    'bbbbbbbb-0000-0000-0000-000000000040',
    'bbbbbbbb-0000-0000-0000-000000000020',
    'bbbbbbbb-0000-0000-0000-000000000030',
    'A-1',
    10
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000042',
    'bbbbbbbb-0000-0000-0000-000000000020',
    'bbbbbbbb-0000-0000-0000-000000000030',
    'A-2',
    10
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000041',
    'bbbbbbbb-0000-0000-0000-000000000020',
    'bbbbbbbb-0000-0000-0000-000000000031',
    'B-1',
    8
  );

insert into public.sales (
  id, branch_id, cashier_id, payment_method_id,
  subtotal, discount_amount, total
) values (
  'bbbbbbbb-0000-0000-0000-000000000050',
  'bbbbbbbb-0000-0000-0000-000000000020',
  'bbbbbbbb-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  130,
  0,
  130
);

insert into public.sale_items (
  id, sale_id, product_id, product_name_snapshot,
  measurement_unit_id, quantity, unit_price, discount_amount, total
) values
  (
    'bbbbbbbb-0000-0000-0000-000000000060',
    'bbbbbbbb-0000-0000-0000-000000000050',
    'bbbbbbbb-0000-0000-0000-000000000030',
    'Refund Product A',
    '10000000-0000-0000-0000-000000000001',
    5,
    10,
    0,
    50
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000061',
    'bbbbbbbb-0000-0000-0000-000000000050',
    'bbbbbbbb-0000-0000-0000-000000000031',
    'Refund Product B',
    '10000000-0000-0000-0000-000000000001',
    4,
    20,
    0,
    80
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000062',
    'bbbbbbbb-0000-0000-0000-000000000050',
    'bbbbbbbb-0000-0000-0000-000000000030',
    'Refund Product A',
    '10000000-0000-0000-0000-000000000001',
    2,
    10,
    0,
    20
  );

insert into public.sale_item_batches (id, sale_item_id, batch_id, quantity)
values
  (
    'bbbbbbbb-0000-0000-0000-000000000070',
    'bbbbbbbb-0000-0000-0000-000000000060',
    'bbbbbbbb-0000-0000-0000-000000000040',
    3
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000072',
    'bbbbbbbb-0000-0000-0000-000000000060',
    'bbbbbbbb-0000-0000-0000-000000000042',
    2
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000071',
    'bbbbbbbb-0000-0000-0000-000000000061',
    'bbbbbbbb-0000-0000-0000-000000000041',
    4
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000073',
    'bbbbbbbb-0000-0000-0000-000000000062',
    'bbbbbbbb-0000-0000-0000-000000000042',
    2
  );

set local role authenticated;
set local request.jwt.claims to
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
declare
  v_refund_base jsonb := jsonb_build_object(
    'original_sale_id', 'bbbbbbbb-0000-0000-0000-000000000050',
    'branch_id', 'bbbbbbbb-0000-0000-0000-000000000020',
    'reason', 'RPC regression',
    'restock', true,
    'total_amount', '9999'
  );
begin
  begin
    perform public.upsert_refund_with_inventory(
      v_refund_base || jsonb_build_object('id', 'bbbbbbbb-0000-0000-0000-000000000100'),
      jsonb_build_array(jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000110',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '1',
        'amount', '999'
      )),
      null
    );
    raise exception 'FAIL: wholesale refund without batch adjustments was accepted';
  exception when others then
    if sqlerrm not like 'Wholesale refund requires batch_adjustments%' then
      raise;
    end if;
  end;

  begin
    perform public.upsert_refund_with_inventory(
      v_refund_base || jsonb_build_object('id', 'bbbbbbbb-0000-0000-0000-000000000101'),
      jsonb_build_array(
        jsonb_build_object(
          'id', 'bbbbbbbb-0000-0000-0000-000000000111',
          'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
          'quantity', '1'
        ),
        jsonb_build_object(
          'id', 'bbbbbbbb-0000-0000-0000-000000000112',
          'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000061',
          'quantity', '1'
        )
      ),
      jsonb_build_array(jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000120',
        'batch_id', 'bbbbbbbb-0000-0000-0000-000000000040',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '2'
      ))
    );
    raise exception 'FAIL: per-product batch restock mismatch was accepted';
  exception when others then
    if sqlerrm not like 'Batch restock quantity must equal refunded quantity per sale item and product%' then
      raise;
    end if;
  end;

  begin
    perform public.upsert_refund_with_inventory(
      v_refund_base || jsonb_build_object('id', 'bbbbbbbb-0000-0000-0000-000000000105'),
      jsonb_build_array(
        jsonb_build_object(
          'id', 'bbbbbbbb-0000-0000-0000-000000000117',
          'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
          'quantity', '1'
        ),
        jsonb_build_object(
          'id', 'bbbbbbbb-0000-0000-0000-000000000118',
          'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000062',
          'quantity', '1'
        )
      ),
      jsonb_build_array(jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000125',
        'batch_id', 'bbbbbbbb-0000-0000-0000-000000000040',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '2'
      ))
    );
    raise exception 'FAIL: same-product sale-item batch restock mismatch was accepted';
  exception when others then
    if sqlerrm not like 'Batch restock quantity must equal refunded quantity per sale item and product%' then
      raise;
    end if;
  end;

  perform public.upsert_refund_with_inventory(
    v_refund_base || jsonb_build_object('id', 'bbbbbbbb-0000-0000-0000-000000000102'),
    jsonb_build_array(
      jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000113',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '1',
        'amount', '500'
      ),
      jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000114',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '1',
        'amount', '500'
      )
    ),
    jsonb_build_array(
      jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000121',
        'batch_id', 'bbbbbbbb-0000-0000-0000-000000000040',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '1'
      ),
      jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000122',
        'batch_id', 'bbbbbbbb-0000-0000-0000-000000000040',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '1'
      )
    )
  );

  if not exists (
    select 1
    from public.refunds
    where id = 'bbbbbbbb-0000-0000-0000-000000000102'
      and total_amount = 20
  ) then
    raise exception 'FAIL: refund total was not computed from sale_items';
  end if;

  if not exists (
    select 1
    from public.refund_items
    where refund_id = 'bbbbbbbb-0000-0000-0000-000000000102'
      and sale_item_id = 'bbbbbbbb-0000-0000-0000-000000000060'
    group by refund_id, sale_item_id
    having sum(quantity) = 2 and sum(amount) = 20 and count(*) = 2
  ) then
    raise exception 'FAIL: duplicate refund item rows were not preserved with server amounts';
  end if;

  if not exists (
    select 1
    from public.batch_adjustments
    where id in (
      'bbbbbbbb-0000-0000-0000-000000000121',
      'bbbbbbbb-0000-0000-0000-000000000122'
    )
      and batch_id = 'bbbbbbbb-0000-0000-0000-000000000040'
      and quantity_delta = -1
    group by batch_id
    having count(*) = 2
  ) then
    raise exception 'FAIL: duplicate batch adjustment rows or client IDs were not preserved';
  end if;

  begin
    perform public.upsert_refund_with_inventory(
      v_refund_base || jsonb_build_object('id', 'bbbbbbbb-0000-0000-0000-000000000104'),
      jsonb_build_array(jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000116',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '2'
      )),
      jsonb_build_array(jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000124',
        'batch_id', 'bbbbbbbb-0000-0000-0000-000000000040',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '2'
      ))
    );
    raise exception 'FAIL: cumulative sale-item batch over-restock was accepted';
  exception when others then
    if sqlerrm not like 'Restock qty exceeds drawn qty%' then
      raise;
    end if;
  end;

  begin
    perform public.upsert_refund_with_inventory(
      v_refund_base || jsonb_build_object('id', 'bbbbbbbb-0000-0000-0000-000000000103'),
      jsonb_build_array(jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000115',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '4'
      )),
      jsonb_build_array(jsonb_build_object(
        'id', 'bbbbbbbb-0000-0000-0000-000000000123',
        'batch_id', 'bbbbbbbb-0000-0000-0000-000000000040',
        'sale_item_id', 'bbbbbbbb-0000-0000-0000-000000000060',
        'quantity', '4'
      ))
    );
    raise exception 'FAIL: over-refund with prior duplicate rows was accepted';
  exception when others then
    if sqlerrm not like 'Refund exceeds quantity sold for item%' then
      raise;
    end if;
  end;

  raise notice 'PASS: upsert_refund_with_inventory validates totals and batch restock';
end;
$$;

rollback;
