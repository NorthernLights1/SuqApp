-- ============================================================
-- Domain 4: Supplies (stubbed — UI deferred to v2, schema ready)
-- ============================================================

create table suppliers (
  id         uuid primary key default gen_random_uuid(),
  shop_id    uuid not null references shops(id) on delete cascade,
  name       text not null,
  phone      text,
  email      text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

create table supply_orders (
  id           uuid primary key default gen_random_uuid(),
  branch_id    uuid not null references branches(id),
  supplier_id  uuid references suppliers(id) on delete set null,
  ordered_by   uuid not null references profiles(id),
  status       text not null default 'draft' check (status in ('draft','ordered','received','cancelled')),
  total_amount numeric(15,4) not null default 0,
  notes        text,
  ordered_at   timestamptz,
  received_at  timestamptz,
  created_at   timestamptz not null default now()
);

create table supply_order_items (
  id                    uuid primary key default gen_random_uuid(),
  supply_order_id       uuid not null references supply_orders(id) on delete cascade,
  product_id            uuid references products(id) on delete set null,
  product_name_snapshot text not null,
  quantity              numeric(15,4) not null,
  unit_cost             numeric(15,4) not null,
  measurement_unit_id   uuid references measurement_units(id)
);

-- ============================================================
-- RLS Policies
-- ============================================================
alter table suppliers          enable row level security;
alter table supply_orders      enable row level security;
alter table supply_order_items enable row level security;

create policy "suppliers_select" on suppliers for select using (is_shop_member(shop_id));
create policy "suppliers_write"  on suppliers for all   using (is_shop_member(shop_id));

create policy "supply_orders_select" on supply_orders for select
  using (is_shop_member(shop_id_from_branch(branch_id)));
create policy "supply_orders_write" on supply_orders for all
  using (is_shop_member(shop_id_from_branch(branch_id)));

create policy "supply_order_items_select" on supply_order_items for select
  using (exists (select 1 from supply_orders so where so.id = supply_order_id and is_shop_member(shop_id_from_branch(so.branch_id))));
create policy "supply_order_items_write" on supply_order_items for all
  using (exists (select 1 from supply_orders so where so.id = supply_order_id and is_shop_member(shop_id_from_branch(so.branch_id))));
