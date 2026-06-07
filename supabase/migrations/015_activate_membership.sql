-- 015_activate_membership.sql
-- Let an invited staff member flip their OWN membership from 'invited' to
-- 'active' on first sign-in.
--
-- shop_users is owner-write-only (policy shop_users_write), so a staff member
-- cannot update their own row — which silently blocked the router's
-- invited->active activation, leaving claimed staff stuck showing as "invited".
-- This SECURITY DEFINER function performs the flip on their behalf, scoped
-- strictly to the caller's own rows and only for invited->active (it will never
-- un-suspend a suspended member). auth.uid() inside a definer function still
-- resolves to the calling user, so it cannot touch anyone else's membership.

create or replace function public.activate_my_membership()
returns void
language sql
security definer
set search_path = public
as $$
  update shop_users
  set status = 'active'
  where user_id = auth.uid() and status = 'invited';
$$;

revoke all on function public.activate_my_membership() from public;
revoke all on function public.activate_my_membership() from anon;
grant execute on function public.activate_my_membership() to authenticated;
