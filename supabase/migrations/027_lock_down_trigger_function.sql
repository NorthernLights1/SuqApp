-- 027_lock_down_trigger_function.sql
-- Security hygiene (Supabase advisor 0028/0029): detect_stock_conflict is a
-- trigger function, not an API. It was callable via /rest/v1/rpc by anon and
-- authenticated as a SECURITY DEFINER function. Triggers fire regardless of
-- EXECUTE grants, so revoking EXECUTE only removes the unintended RPC surface
-- without affecting the trigger on the inventory table.

revoke all on function public.detect_stock_conflict()
  from public, anon, authenticated;
