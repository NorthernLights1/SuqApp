-- 021_stock_conflicts.sql
-- Offline-first oversell detection. When two phones sell the same stock while
-- offline, both sales sync and the server inventory can go negative. A trigger
-- records that as a "stock conflict" for the owner to resolve.
--
-- Detection is server-side (authoritative, regardless of which device caused
-- it). Resolution = the owner enters the true physical count, which corrects
-- inventory and closes the conflict (see the app's resolution screen).

create table stock_conflicts (
  id                uuid primary key default gen_random_uuid(),
  branch_id         uuid not null references branches(id) on delete cascade,
  product_id        uuid not null references products(id) on delete cascade,
  observed_quantity numeric(15,4) not null,  -- the negative quantity seen
  detected_at       timestamptz not null default now(),
  resolved_at       timestamptz,
  resolved_by       uuid references profiles(id) on delete set null,
  resolution_note   text,
  emailed_at        timestamptz
);

-- At most one OPEN conflict per product/branch (re-detections update it).
create unique index stock_conflicts_open_idx
  on stock_conflicts(branch_id, product_id) where resolved_at is null;
create index stock_conflicts_branch_idx on stock_conflicts(branch_id);

alter table stock_conflicts enable row level security;

-- Shop members can see their shop's conflicts.
create policy "stock_conflicts_select" on stock_conflicts for select
  using (private.is_shop_member(private.shop_id_from_branch(branch_id)));

-- Only the shop owner resolves them.
create policy "stock_conflicts_update" on stock_conflicts for update
  using (exists (
    select 1 from branches b join shops s on s.id = b.shop_id
    where b.id = branch_id and s.owner_id = auth.uid()
  ));

grant select, update on stock_conflicts to authenticated;
grant select, insert, update, delete on stock_conflicts to service_role;

-- ── Detection trigger ─────────────────────────────────────────────────────────
-- SECURITY DEFINER so the insert bypasses RLS (the writer is the DB itself, on
-- behalf of whichever sync pushed the oversell).

create or replace function detect_stock_conflict()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if NEW.quantity < 0 then
    insert into stock_conflicts (branch_id, product_id, observed_quantity)
    values (NEW.branch_id, NEW.product_id, NEW.quantity)
    on conflict (branch_id, product_id) where resolved_at is null
      do update set observed_quantity = excluded.observed_quantity,
                    detected_at = now();
  end if;
  return NEW;
end;
$$;

create trigger trg_detect_stock_conflict
  after insert or update of quantity on inventory
  for each row execute function detect_stock_conflict();
