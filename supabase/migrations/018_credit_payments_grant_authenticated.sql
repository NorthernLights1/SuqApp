-- 018_credit_payments_grant_authenticated.sql
-- Fix: the Credits screen failed with "permission denied for table
-- credit_payments" (PostgREST 42501). Migration 017 enabled RLS and granted
-- privileges to service_role only, but the app connects as the `authenticated`
-- role. RLS decides WHICH rows are visible; the role still needs base table
-- privileges to touch the table at all.
--
-- Grant only select + insert: payment rows are an immutable dispute audit
-- trail, so end users get no update/delete (this also mirrors the RLS in 017,
-- which has no update/delete policy). service_role keeps full access.

grant select, insert on credit_payments to authenticated;
