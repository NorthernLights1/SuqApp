-- rls_isolation_test.sql  (Phase A — RLS audit, run manually; read-only)
-- Verifies the wall that matters: the anon key ships inside the APK, so RLS is
-- the ONLY thing stopping one shop's user from reading another shop's data.
-- Nothing here writes — Part 2 runs in a transaction that is rolled back.

-- ════════════════════════════════════════════════════════════════════════════
-- PART 1 — Coverage: every replica table must have RLS ENABLED.
-- Expected result: ZERO rows. Any row = a table with RLS off = a hole.
-- ════════════════════════════════════════════════════════════════════════════
select c.relname as table_without_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname = any (array[
    'shops','branches','shop_settings','payment_methods','product_categories',
    'measurement_units','products','inventory','inventory_adjustments','sales',
    'sale_items','customers','expenses','expense_categories','credit_payments',
    'profiles'])
  and c.relrowsecurity = false;

-- Also list each replica table's policies, for an eyeball pass.
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename = any (array[
    'shops','branches','shop_settings','payment_methods','product_categories',
    'measurement_units','products','inventory','inventory_adjustments','sales',
    'sale_items','customers','expenses','expense_categories','credit_payments',
    'profiles'])
order by tablename, cmd;

-- ════════════════════════════════════════════════════════════════════════════
-- PART 2 — Cross-shop isolation: a user in shop B must see NONE of shop A's rows.
--
-- SETUP: pick two real accounts that belong to DIFFERENT shops, then fill in:
--   :user_b_uuid  — auth.users.id of a member/owner of shop B
--   :shop_a_id    — shops.id of shop A (the OTHER shop, that user B must NOT see)
-- Find them with:
--   select su.user_id, su.shop_id from shop_users su order by su.shop_id;
--
-- Replace the two literals below, then run the whole block. It RAISES if any
-- shop-A row is visible to user B. Rolls back — writes nothing.
-- ════════════════════════════════════════════════════════════════════════════
begin;

-- Simulate "logged in as user B" exactly as PostgREST does for the anon/app key.
set local role authenticated;
set local request.jwt.claims to '{"sub":"REPLACE_WITH_USER_B_UUID","role":"authenticated"}';

do $$
declare
  shop_a constant uuid := 'REPLACE_WITH_SHOP_A_ID';
  leaked int;
begin
  -- Direct shop_id-scoped tables
  select count(*) into leaked from public.products            where shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: products (% rows of shop A visible)', leaked; end if;

  select count(*) into leaked from public.customers           where shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: customers (% rows)', leaked; end if;

  select count(*) into leaked from public.product_categories  where shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: product_categories (% rows)', leaked; end if;

  select count(*) into leaked from public.shop_settings       where shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: shop_settings (% rows)', leaked; end if;

  select count(*) into leaked from public.branches            where shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: branches (% rows)', leaked; end if;

  -- Branch-scoped tables (joined back to shop A via branch)
  select count(*) into leaked from public.sales s
    join public.branches b on b.id = s.branch_id where b.shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: sales (% rows)', leaked; end if;

  select count(*) into leaked from public.inventory_adjustments ia
    join public.branches b on b.id = ia.branch_id where b.shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: inventory_adjustments (% rows)', leaked; end if;

  select count(*) into leaked from public.sale_items si
    join public.sales s on s.id = si.sale_id
    join public.branches b on b.id = s.branch_id where b.shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: sale_items (% rows)', leaked; end if;

  select count(*) into leaked from public.inventory i
    join public.branches b on b.id = i.branch_id where b.shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: inventory (% rows)', leaked; end if;

  select count(*) into leaked from public.expenses e
    join public.branches b on b.id = e.branch_id where b.shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: expenses (% rows)', leaked; end if;

  select count(*) into leaked from public.credit_payments cp
    join public.sales s on s.id = cp.sale_id
    join public.branches b on b.id = s.branch_id where b.shop_id = shop_a;
  if leaked > 0 then raise exception 'LEAK: credit_payments (% rows)', leaked; end if;

  raise notice 'PASS: user B sees no rows of shop A across all checked tables.';
end;
$$;

rollback;

-- ── Known-and-intended cross-shop visibility (NOT leaks) ─────────────────────
-- * measurement_units / payment_methods / expense_categories with shop_id IS
--   NULL are SYSTEM rows shared by every shop, by design.
-- * profiles: a shopmate's name/phone is visible to others in the SAME shop via
--   private.shares_shop_with() (migration 014) — intended for "Sold by" labels.
-- These are shared reference data, not another shop's private business data.
