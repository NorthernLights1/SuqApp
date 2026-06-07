-- 014_profiles_shopmate_read.sql
-- Let users who share a shop read each other's display profile (full_name,
-- phone) so the staff list shows real names instead of "Unknown".
--
-- The name already lives on profiles and is written by each user for their own
-- row (profiles RLS: auth.uid() = id). Only the READ was locked to the owner of
-- the row, so the owner couldn't see staff names. This opens the read to
-- shopmates using a SECURITY DEFINER helper (same pattern as
-- private.is_shop_member) — the membership check runs with definer rights, so
-- it bypasses RLS internally and cannot recurse.

create or replace function private.shares_shop_with(p_target uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from shop_users me
    join shop_users them on them.shop_id = me.shop_id
    where me.user_id = auth.uid()
      and them.user_id = p_target
  );
$$;

-- Internal helper: only signed-in users may call it.
revoke all on function private.shares_shop_with(uuid) from public;
revoke all on function private.shares_shop_with(uuid) from anon;
grant execute on function private.shares_shop_with(uuid) to authenticated;

-- Replace the self-only read policy with self OR shopmate.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select
  using (auth.uid() = id or private.shares_shop_with(id));
