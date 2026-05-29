-- ============================================================
-- Domain 1: Identity & Access
-- ============================================================

-- Profiles extend Supabase auth.users
create table profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text not null,
  phone        text,
  avatar_url   text,
  created_at   timestamptz not null default now()
);

create table shops (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid not null references profiles(id),
  name       text not null,
  config     jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table branches (
  id         uuid primary key default gen_random_uuid(),
  shop_id    uuid not null references shops(id) on delete cascade,
  name       text not null,
  address    text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

-- System roles: owner, manager, cashier. Shops can add custom roles.
create table roles (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid references shops(id) on delete cascade, -- null = system role
  name        text not null,
  is_system   boolean not null default false,
  created_at  timestamptz not null default now()
);

create table permissions (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  module      text not null,
  description text
);

create table role_permissions (
  role_id       uuid not null references roles(id) on delete cascade,
  permission_id uuid not null references permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

create table shop_users (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid not null references shops(id) on delete cascade,
  branch_id   uuid references branches(id) on delete set null, -- null = all branches
  user_id     uuid not null references profiles(id),
  role_id     uuid not null references roles(id),
  status      text not null default 'active' check (status in ('active','invited','suspended')),
  invited_by  uuid references profiles(id),
  created_at  timestamptz not null default now(),
  unique(shop_id, user_id)
);

-- ============================================================
-- Seed: System roles
-- ============================================================
insert into roles (id, shop_id, name, is_system) values
  ('00000000-0000-0000-0000-000000000001', null, 'owner',   true),
  ('00000000-0000-0000-0000-000000000002', null, 'manager', true),
  ('00000000-0000-0000-0000-000000000003', null, 'cashier', true);

-- ============================================================
-- Seed: Permission codes
-- ============================================================
insert into permissions (code, module, description) values
  ('sales.create',              'sales',           'Create a new sale'),
  ('sales.view',                'sales',           'View sales list and details'),
  ('sales.void',                'sales',           'Void any sale'),
  ('sales.refund_own',          'sales',           'Refund own sales'),
  ('sales.refund_any',          'sales',           'Refund any sale (owner only by default)'),
  ('inventory.view',            'inventory',       'View inventory'),
  ('inventory.edit',            'inventory',       'Edit inventory records'),
  ('inventory.adjust',          'inventory',       'Make manual inventory adjustments'),
  ('supplies.view',             'supplies',        'View supply orders'),
  ('supplies.manage',           'supplies',        'Create and manage supply orders'),
  ('customers.view',            'customers',       'View customers'),
  ('customers.manage',          'customers',       'Create and manage customers'),
  ('expenses.view',             'expenses',        'View expenses'),
  ('expenses.manage',           'expenses',        'Record and manage expenses'),
  ('reports.view',              'reports',         'View reports'),
  ('reports.export',            'reports',         'Export reports'),
  ('staff.view',                'staff',           'View staff list'),
  ('staff.manage',              'staff',           'Invite and manage staff'),
  ('settings.view',             'settings',        'View shop settings'),
  ('settings.manage',           'settings',        'Modify shop settings'),
  ('reconciliation.view',       'reconciliation',  'View cash reconciliations'),
  ('reconciliation.manage',     'reconciliation',  'Create cash reconciliations');

-- ============================================================
-- Seed: Role → Permission assignments
-- ============================================================

-- Owner gets everything
insert into role_permissions (role_id, permission_id)
select '00000000-0000-0000-0000-000000000001', id from permissions;

-- Manager: sales + inventory + supplies + customers + expenses + reports + reconciliation
insert into role_permissions (role_id, permission_id)
select '00000000-0000-0000-0000-000000000002', id from permissions
where code in (
  'sales.create','sales.view','sales.refund_own',
  'inventory.view','inventory.edit','inventory.adjust',
  'supplies.view','supplies.manage',
  'customers.view','customers.manage',
  'expenses.view','expenses.manage',
  'reports.view','reports.export',
  'reconciliation.view','reconciliation.manage'
);

-- Cashier: sales create/view + inventory view + refund own
insert into role_permissions (role_id, permission_id)
select '00000000-0000-0000-0000-000000000003', id from permissions
where code in (
  'sales.create','sales.view','sales.refund_own',
  'inventory.view'
);

-- ============================================================
-- RLS Policies
-- ============================================================
alter table profiles      enable row level security;
alter table shops         enable row level security;
alter table branches      enable row level security;
alter table roles         enable row level security;
alter table permissions   enable row level security;
alter table role_permissions enable row level security;
alter table shop_users    enable row level security;

-- Profiles: users can read/update their own profile
create policy "profiles_select" on profiles for select using (auth.uid() = id);
create policy "profiles_update" on profiles for update using (auth.uid() = id);
create policy "profiles_insert" on profiles for insert with check (auth.uid() = id);

-- Shops: owner can do anything; members can read
create policy "shops_select" on shops for select
  using (
    owner_id = auth.uid() or
    exists (select 1 from shop_users where shop_id = shops.id and user_id = auth.uid() and status = 'active')
  );
create policy "shops_insert" on shops for insert with check (owner_id = auth.uid());
create policy "shops_update" on shops for update using (owner_id = auth.uid());

-- Branches: shop members can read; owner can write
create policy "branches_select" on branches for select
  using (exists (select 1 from shop_users where shop_id = branches.shop_id and user_id = auth.uid() and status = 'active')
         or exists (select 1 from shops where id = branches.shop_id and owner_id = auth.uid()));
create policy "branches_write" on branches for all
  using (exists (select 1 from shops where id = branches.shop_id and owner_id = auth.uid()));

-- Roles: readable by shop members
create policy "roles_select" on roles for select
  using (shop_id is null or exists (select 1 from shop_users where shop_id = roles.shop_id and user_id = auth.uid()));

-- Permissions: readable by all authenticated users
create policy "permissions_select" on permissions for select using (auth.uid() is not null);
create policy "role_permissions_select" on role_permissions for select using (auth.uid() is not null);

-- Shop users: readable by shop members
create policy "shop_users_select" on shop_users for select
  using (user_id = auth.uid() or
         exists (select 1 from shops where id = shop_users.shop_id and owner_id = auth.uid()));
create policy "shop_users_write" on shop_users for all
  using (exists (select 1 from shops where id = shop_users.shop_id and owner_id = auth.uid()));
