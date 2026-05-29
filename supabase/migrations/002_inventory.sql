-- ============================================================
-- Domain 2: Inventory
-- ============================================================

create table measurement_units (
  id            uuid primary key default gen_random_uuid(),
  shop_id       uuid references shops(id) on delete cascade, -- null = system unit
  name          text not null,
  abbreviation  text not null,
  is_system     boolean not null default false
);

create table product_categories (
  id        uuid primary key default gen_random_uuid(),
  shop_id   uuid not null references shops(id) on delete cascade,
  name      text not null,
  parent_id uuid references product_categories(id) on delete set null
);

create table products (
  id                       uuid primary key default gen_random_uuid(),
  shop_id                  uuid not null references shops(id) on delete cascade,
  category_id              uuid references product_categories(id) on delete set null,
  name                     text not null,
  description              text,
  measurement_unit_id      uuid not null references measurement_units(id),
  low_stock_threshold      numeric(15,4) not null default 0,
  is_active                boolean not null default true,
  created_at               timestamptz not null default now()
);

create table inventory (
  id          uuid primary key default gen_random_uuid(),
  branch_id   uuid not null references branches(id) on delete cascade,
  product_id  uuid not null references products(id) on delete cascade,
  quantity    numeric(15,4) not null default 0,
  updated_at  timestamptz not null default now(),
  unique(branch_id, product_id)
);

create table inventory_adjustments (
  id               uuid primary key default gen_random_uuid(),
  branch_id        uuid not null references branches(id),
  product_id       uuid not null references products(id),
  adjusted_by      uuid not null references profiles(id),
  type             text not null check (type in ('opening_stock','sale','refund','manual','supply_received','void')),
  quantity_before  numeric(15,4) not null,
  quantity_after   numeric(15,4) not null,
  reference_id     uuid,
  reference_type   text,
  notes            text,
  created_at       timestamptz not null default now()
);

-- ============================================================
-- Seed: System measurement units
-- ============================================================
insert into measurement_units (id, shop_id, name, abbreviation, is_system) values
  ('10000000-0000-0000-0000-000000000001', null, 'Piece',  'pcs',  true),
  ('10000000-0000-0000-0000-000000000002', null, 'Kilogram','kg',  true),
  ('10000000-0000-0000-0000-000000000003', null, 'Litre',  'L',    true),
  ('10000000-0000-0000-0000-000000000004', null, 'Pack',   'pack', true),
  ('10000000-0000-0000-0000-000000000005', null, 'Gram',   'g',    true),
  ('10000000-0000-0000-0000-000000000006', null, 'Metre',  'm',    true);

-- ============================================================
-- RLS Policies
-- ============================================================
alter table measurement_units      enable row level security;
alter table product_categories     enable row level security;
alter table products               enable row level security;
alter table inventory              enable row level security;
alter table inventory_adjustments  enable row level security;

-- Helper: check if user is active member of a shop
create or replace function is_shop_member(p_shop_id uuid)
returns boolean language sql security definer as $$
  select exists (
    select 1 from shop_users
    where shop_id = p_shop_id and user_id = auth.uid() and status = 'active'
  ) or exists (
    select 1 from shops where id = p_shop_id and owner_id = auth.uid()
  );
$$;

-- Helper: get shop_id from branch_id
create or replace function shop_id_from_branch(p_branch_id uuid)
returns uuid language sql security definer as $$
  select shop_id from branches where id = p_branch_id;
$$;

create policy "measurement_units_select" on measurement_units for select
  using (shop_id is null or is_shop_member(shop_id));
create policy "measurement_units_write" on measurement_units for all
  using (shop_id is not null and is_shop_member(shop_id));

create policy "product_categories_select" on product_categories for select
  using (is_shop_member(shop_id));
create policy "product_categories_write" on product_categories for all
  using (is_shop_member(shop_id));

create policy "products_select" on products for select using (is_shop_member(shop_id));
create policy "products_write"  on products for all   using (is_shop_member(shop_id));

create policy "inventory_select" on inventory for select
  using (is_shop_member(shop_id_from_branch(branch_id)));
create policy "inventory_write" on inventory for all
  using (is_shop_member(shop_id_from_branch(branch_id)));

create policy "inventory_adjustments_select" on inventory_adjustments for select
  using (is_shop_member(shop_id_from_branch(branch_id)));
create policy "inventory_adjustments_insert" on inventory_adjustments for insert
  with check (is_shop_member(shop_id_from_branch(branch_id)));
