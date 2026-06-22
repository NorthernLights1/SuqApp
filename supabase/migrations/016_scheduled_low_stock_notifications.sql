-- 016_scheduled_low_stock_notifications.sql
-- Scheduled (server-side) low-stock notifications, replacing the per-sale trigger.
--
-- Runs twice daily via pg_cron at 06:00 and 18:00 UTC (= 9 AM / 9 PM EAT). A cron
-- job calls the `cron-notifications` Edge Function (deployed separately), which
-- loops every shop, sends low-stock email alerts to the OWNER'S email by default
-- (plus the optional `notification_email` shop setting), and emails via Resend.
--
-- This migration holds the portable DB pieces. The Vault secret, cron jobs, and
-- the Edge Function are environment-specific and were applied to the live
-- project (documented at the bottom for reproducibility).

-- 1) Scheduler extensions
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 2) Auth gate for the cron-notifications function. The function is public
-- (verify_jwt:false) but only runs when called with the Vault-stored cron
-- secret. It verifies the incoming secret through this SECURITY DEFINER RPC
-- (so the secret never has to live in the function's env).
create or replace function public.verify_cron_secret(p_secret text)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from vault.decrypted_secrets
    where name = 'cron_secret' and decrypted_secret = p_secret
  );
$$;

revoke all on function public.verify_cron_secret(text) from public, anon, authenticated;
grant execute on function public.verify_cron_secret(text) to service_role;

-- 3) Applied to the live project via MCP (kept here as documentation; values are
--    environment-specific so they are not re-run by this migration):
--
--   -- random cron secret in Vault:
--   select vault.create_secret(encode(gen_random_bytes(24),'hex'), 'cron_secret',
--                              'auth for scheduled notifications');
--
--   -- two schedules calling the Edge Function via pg_net, reading the secret
--   -- from Vault at run time:
--   select cron.schedule('low-stock-am', '0 6 * * *',  $$ select net.http_post(
--     url := 'https://<ref>.supabase.co/functions/v1/cron-notifications',
--     headers := jsonb_build_object('Content-Type','application/json',
--       'apikey','<publishable key>',
--       'x-cron-secret',(select decrypted_secret from vault.decrypted_secrets where name='cron_secret')),
--     body := jsonb_build_object('source','cron')); $$);
--   select cron.schedule('low-stock-pm', '0 18 * * *', $$ ...same... $$);
--
--   Edge Function: cron-notifications (verify_jwt:false) — loops all shops,
--   recipients = owner auth email (default) + optional notification_email,
--   low-stock query (inventory JOIN products where quantity <= low_stock_threshold),
--   sends via Resend. Verified end-to-end (200, email sent to owner).
