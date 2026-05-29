-- ============================================================
-- Domain 3: Sales
-- ============================================================

create table payment_methods (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid references shops(id) on delete cascade, -- null = system method
  name        text not null,
  code        text not null,
  is_active   boolean not null default true,
  is_system   boolean not null default false,
  config      jsonb not null default '{}'
);

create table customers (
  id             uuid primary key default gen_random_uuid(),
  shop_id        uuid not null references shops(id) on delete cascade,
  name           text not null,
  phone          text,
  credit_balance numeric(15,4) not null default 0,
  created_at     timestamptz not null default now()
);

create table sales (
  id                  uuid primary key default gen_random_uuid(),
  branch_id           uuid not null references branches(id),
  customer_id         uuid references customers(id) on delete set null,
  cashier_id          uuid not null references profiles(id),
  payment_method_id   uuid not null references payment_methods(id),
  subtotal            numeric(15,4) not null,
  discount_amount     numeric(15,4) not null default 0,
  total               numeric(15,4) not null,
  status              text not null default 'completed' check (status in ('completed','voided','refunded')),
  void_reason         text,
  voided_by           uuid references profiles(id),
  voided_at           timestamptz,
  is_credit           boolean not null default false,
  notes               text,
  created_at          timestamptz not null default now()
);

create table sale_items (
  id                      uuid primary key default gen_random_uuid(),
  sale_id                 uuid not null references sales(id) on delete cascade,
  product_id              uuid references products(id) on delete set null,
  product_name_snapshot   text not null,  -- never loses history if product renamed
  measurement_unit_id     uuid references measurement_units(id),
  quantity                numeric(15,4) not null,
  unit_price              numeric(15,4) not null,
  discount_amount         numeric(15,4) not null default 0,
  total                   numeric(15,4) not null,
  inventory_status        text not null default 'tracked' check (inventory_status in ('tracked','untracked','flagged'))
);

create table discounts (
  id           uuid primary key default gen_random_uuid(),
  sale_id      uuid not null references sales(id) on delete cascade,
  sale_item_id uuid references sale_items(id) on delete cascade,
  given_by     uuid not null references profiles(id),
  type         text not null check (type in ('percentage','fixed')),
  value        numeric(15,4) not null,
  reason       text not null,
  created_at   timestamptz not null default now()
);

create table refunds (
  id               uuid primary key default gen_random_uuid(),
  original_sale_id uuid not null references sales(id),
  refunded_by      uuid not null references profiles(id),
  reason           text not null,
  total_amount     numeric(15,4) not null,
  created_at       timestamptz not null default now()
);

create table refund_items (
  id           uuid primary key default gen_random_uuid(),
  refund_id    uuid not null references refunds(id) on delete cascade,
  sale_item_id uuid not null references sale_items(id),
  quantity     numeric(15,4) not null,
  amount       numeric(15,4) not null
);

-- ============================================================
-- Seed: System payment methods
-- ============================================================
insert into payment_methods (id, shop_id, name, code, is_active, is_system) values
  ('20000000-0000-0000-0000-000000000001', null, 'Cash',          'cash',          true, true),
  ('20000000-0000-0000-0000-000000000002', null, 'Bank Transfer', 'bank_transfer', true, true);
-- Chapa will be inserted here when integrated (is_system = false, config holds API keys)

-- ============================================================
-- RLS Policies
-- ============================================================
alter table payment_methods  enable row level security;
alter table customers        enable row level security;
alter table sales            enable row level security;
alter table sale_items       enable row level security;
alter table discounts        enable row level security;
alter table refunds          enable row level security;
alter table refund_items     enable row level security;

create policy "payment_methods_select" on payment_methods for select
  using (shop_id is null or is_shop_member(shop_id));
create policy "payment_methods_write" on payment_methods for all
  using (shop_id is not null and is_shop_member(shop_id));

create policy "customers_select" on customers for select using (is_shop_member(shop_id));
create policy "customers_write"  on customers for all   using (is_shop_member(shop_id));

create policy "sales_select" on sales for select
  using (is_shop_member(shop_id_from_branch(branch_id)));
create policy "sales_insert" on sales for insert
  with check (is_shop_member(shop_id_from_branch(branch_id)));
create policy "sales_update" on sales for update
  using (is_shop_member(shop_id_from_branch(branch_id)));

create policy "sale_items_select" on sale_items for select
  using (exists (select 1 from sales s where s.id = sale_id and is_shop_member(shop_id_from_branch(s.branch_id))));
create policy "sale_items_insert" on sale_items for insert
  with check (exists (select 1 from sales s where s.id = sale_id and is_shop_member(shop_id_from_branch(s.branch_id))));

create policy "discounts_select" on discounts for select
  using (exists (select 1 from sales s where s.id = sale_id and is_shop_member(shop_id_from_branch(s.branch_id))));
create policy "discounts_insert" on discounts for insert
  with check (exists (select 1 from sales s where s.id = sale_id and is_shop_member(shop_id_from_branch(s.branch_id))));

create policy "refunds_select" on refunds for select
  using (exists (select 1 from sales s where s.id = original_sale_id and is_shop_member(shop_id_from_branch(s.branch_id))));
create policy "refunds_insert" on refunds for insert
  with check (exists (select 1 from sales s where s.id = original_sale_id and is_shop_member(shop_id_from_branch(s.branch_id))));

create policy "refund_items_select" on refund_items for select
  using (exists (select 1 from refunds r join sales s on s.id = r.original_sale_id where r.id = refund_id and is_shop_member(shop_id_from_branch(s.branch_id))));
create policy "refund_items_insert" on refund_items for insert
  with check (exists (select 1 from refunds r join sales s on s.id = r.original_sale_id where r.id = refund_id and is_shop_member(shop_id_from_branch(s.branch_id))));
