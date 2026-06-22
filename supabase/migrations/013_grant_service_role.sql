-- 013_grant_service_role.sql
-- Restore service_role's standard DML privileges on all public tables.
--
-- service_role is used exclusively server-side (Edge Functions, via the secret
-- key) and is never exposed to clients, so this does NOT weaken RLS — RLS still
-- governs anon/authenticated. A prior blanket REVOKE had stripped service_role's
-- SELECT/INSERT/UPDATE/DELETE across the whole schema, which caused
-- "permission denied for table ..." in the invite-staff and
-- dispatch-notifications Edge Functions (their owner-check queries silently
-- returned nothing, producing 403s on every invite and notification).

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO service_role;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO service_role;
