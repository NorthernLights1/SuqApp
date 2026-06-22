-- 025_one_shop_one_branch.sql
-- Product rule (offline-first v2): one email = one shop = one branch.
-- Multi-shop membership and multi-branch are deferred, not removed — branch_id
-- stays in the schema (load-bearing for sync/RLS/inventory). This migration
-- only forbids creating a *second* shop per user or a *second* branch per shop.
--
-- Safe to apply: a pre-check confirmed no existing rows violate these (0 users
-- in >1 shop, 0 shops with >1 live branch, 0 owners with >1 shop). Idempotent.

-- ── Enforcement: one membership per user, one owned shop per user ─────────────
create unique index if not exists shop_users_one_shop_per_user_uidx
  on public.shop_users (user_id);

create unique index if not exists shops_one_per_owner_uidx
  on public.shops (owner_id);

-- One LIVE branch per shop (deleted_at tombstones don't count, so a replaced
-- branch is still allowed). Drop this index to re-enable multi-branch later.
create unique index if not exists branches_one_live_per_shop_uidx
  on public.branches (shop_id) where deleted_at is null;

-- ── Friendly guards in the onboarding RPCs (clearer than a raw 23505) ─────────
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
  -- One email = one shop: a user who already owns or belongs to a shop cannot
  -- create another.
  if exists (select 1 from public.shop_users where user_id = auth.uid())
     or exists (select 1 from public.shops where owner_id = auth.uid()) then
    raise exception 'You already have a shop on this account';
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
  -- One shop = one branch (current product rule).
  if exists (
    select 1 from public.branches
    where shop_id = p_shop_id and deleted_at is null
  ) then
    raise exception 'This shop already has a branch';
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
