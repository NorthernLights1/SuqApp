-- ============================================================
-- 035 — Lock down batch trigger functions (advisor 0028/0029)
-- ============================================================
-- Phase D security audit follow-up. The batch chain (028–032) added several
-- SECURITY DEFINER *trigger* functions that — like detect_stock_conflict before
-- migration 027 — are unintentionally callable via /rest/v1/rpc by anon and
-- authenticated roles. They are internal: they fire from triggers, never as an
-- API, and the app never calls them via rpc(). Triggers fire regardless of
-- EXECUTE grants, so revoking EXECUTE removes the RPC surface with no functional
-- impact.
revoke all on function public.detect_batch_conflict(uuid)
  from public, anon, authenticated;
revoke all on function public.recompute_product_rollup(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.on_product_batches_change()
  from public, anon, authenticated;
revoke all on function public.on_sale_item_batches_change()
  from public, anon, authenticated;
revoke all on function public.on_batch_adjustments_change()
  from public, anon, authenticated;
