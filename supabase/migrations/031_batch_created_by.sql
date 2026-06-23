-- 031_batch_created_by.sql
-- Record WHO added each lot, for the wholesale per-batch "Details" view.
--
-- product_batches are created device-side (stock-in / opening stock) and pushed
-- as a replica upsert, so created_by is set by the client (the adjusting user).
-- Nullable: backfilled rows (028) and any pre-existing lots have no author.
-- Plain uuid (no FK) to match the other user-id columns and avoid push-order
-- coupling; the app resolves the display name from its profiles mirror.
--
-- Idempotent. Applied via MCP.

alter table public.product_batches
  add column if not exists created_by uuid;
