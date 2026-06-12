-- 020_license_periods.sql
-- Licenses are now time-boxed instead of perpetual:
--   * each serial carries its own validity period (duration_days, chosen at
--     generation time);
--   * activating sets shop_controls.licensed_until = now() + duration. No
--     stacking: re-activating starts the new period from today.
--   * when licensed_until passes, the app locks again and asks for a fresh
--     serial.
-- Also enforces unique shop names (case-insensitive) so anyone can self-serve
-- a shop with a unique email + shop name.

alter table license_keys
  add column duration_days integer not null default 30
  check (duration_days > 0);

alter table shop_controls drop column licensed;
alter table shop_controls add column licensed_until timestamptz;

create unique index shops_name_unique_idx on shops (lower(name));

-- Re-create activation to consume the key's duration.
create or replace function activate_license(p_shop_id uuid, p_key text)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_duration integer;
begin
  -- caller must own the shop
  if not exists (
    select 1 from shops where id = p_shop_id and owner_id = auth.uid()
  ) then
    return false;
  end if;

  -- claim the key atomically (single-use)
  update license_keys
  set used_by = p_shop_id, used_at = now()
  where key = p_key and used_by is null
  returning duration_days into v_duration;

  if v_duration is null then
    return false; -- unknown or already-used key
  end if;

  insert into shop_controls (shop_id, licensed_until, licensed_at, license_key, updated_at)
  values (p_shop_id, now() + make_interval(days => v_duration), now(), p_key, now())
  on conflict (shop_id) do update
    set licensed_until = now() + make_interval(days => v_duration),
        licensed_at    = now(),
        license_key    = excluded.license_key,
        updated_at     = now();

  return true;
end;
$$;
