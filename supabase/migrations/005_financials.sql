-- ============================================================
-- Domain 5: Financials
-- ============================================================

create table expense_categories (
  id        uuid primary key default gen_random_uuid(),
  shop_id   uuid references shops(id) on delete cascade, -- null = system category
  name      text not null,
  is_system boolean not null default false
);

create table expenses (
  id          uuid primary key default gen_random_uuid(),
  branch_id   uuid not null references branches(id),
  category_id uuid not null references expense_categories(id),
  amount      numeric(15,4) not null,
  description text,
  recorded_by uuid not null references profiles(id),
  date        date not null,
  created_at  timestamptz not null default now()
);

create table cash_reconciliations (
  id             uuid primary key default gen_random_uuid(),
  branch_id      uuid not null references branches(id),
  reconciled_by  uuid not null references profiles(id),
  date           date not null,
  opening_cash   numeric(15,4) not null,
  closing_cash   numeric(15,4) not null,
  expected_cash  numeric(15,4) not null,
  difference     numeric(15,4) not null,
  notes          text,
  created_at     timestamptz not null default now(),
  unique(branch_id, date)
);

-- ============================================================
-- Seed: System expense categories
-- ============================================================
insert into expense_categories (id, shop_id, name, is_system) values
  ('30000000-0000-0000-0000-000000000001', null, 'Rent',       true),
  ('30000000-0000-0000-0000-000000000002', null, 'Transport',  true),
  ('30000000-0000-0000-0000-000000000003', null, 'Utilities',  true),
  ('30000000-0000-0000-0000-000000000004', null, 'Salary',     true),
  ('30000000-0000-0000-0000-000000000005', null, 'Other',      true);

-- ============================================================
-- RLS Policies
-- ============================================================
alter table expense_categories    enable row level security;
alter table expenses              enable row level security;
alter table cash_reconciliations  enable row level security;

create policy "expense_categories_select" on expense_categories for select
  using (shop_id is null or is_shop_member(shop_id));
create policy "expense_categories_write" on expense_categories for all
  using (shop_id is not null and is_shop_member(shop_id));

create policy "expenses_select" on expenses for select
  using (is_shop_member(shop_id_from_branch(branch_id)));
create policy "expenses_write" on expenses for all
  using (is_shop_member(shop_id_from_branch(branch_id)));

create policy "cash_reconciliations_select" on cash_reconciliations for select
  using (is_shop_member(shop_id_from_branch(branch_id)));
create policy "cash_reconciliations_write" on cash_reconciliations for all
  using (is_shop_member(shop_id_from_branch(branch_id)));
