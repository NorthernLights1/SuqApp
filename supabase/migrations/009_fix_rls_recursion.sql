-- Fix: infinite recursion between shops_select and shop_users_select RLS policies.
-- shops_select checked shop_users; shop_users_select checked shops → cycle → 42P17.
-- Fix: introduce a security definer helper that reads shop_users bypassing RLS,
-- then use it as the membership check inside shops_select.

-- Drop the recursive policies and the branches policies that chain through them
drop policy if exists "shops_select"      on shops;
drop policy if exists "shop_users_select" on shop_users;
drop policy if exists "shop_users_write"  on shop_users;
drop policy if exists "branches_select"   on branches;
drop policy if exists "branches_write"    on branches;

-- Helper: returns true if the current user is an active member of the shop.
-- security definer + set search_path bypasses RLS on shop_users → no recursion.
create or replace function is_shop_member(p_shop_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from shop_users
    where shop_id  = p_shop_id
      and user_id  = auth.uid()
      and status   = 'active'
  );
$$;

-- Shops: owner always; members via helper (no RLS chain)
create policy "shops_select" on shops for select
  using (owner_id = auth.uid() or is_shop_member(id));

-- Shop users: own row always; owner sees all shop members
create policy "shop_users_select" on shop_users for select
  using (
    user_id = auth.uid() or
    exists (select 1 from shops where id = shop_users.shop_id and owner_id = auth.uid())
  );

create policy "shop_users_write" on shop_users for all
  using (
    exists (select 1 from shops where id = shop_users.shop_id and owner_id = auth.uid())
  );

-- Branches: use helper to avoid chaining through shop_users RLS
create policy "branches_select" on branches for select
  using (
    is_shop_member(shop_id) or
    exists (select 1 from shops where id = shop_id and owner_id = auth.uid())
  );

create policy "branches_write" on branches for all
  using (
    exists (select 1 from shops where id = shop_id and owner_id = auth.uid())
  );
