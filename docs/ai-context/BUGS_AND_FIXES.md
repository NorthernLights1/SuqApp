# Bugs and Fixes — Suq ERP

---

## Bug: Signup fails with 500 "Database error saving new user"
Status: Fixed

Symptoms: Signup form submission returns `AuthRetryableFetchException statusCode: 500`.
Cause: `handle_new_user()` trigger missing `set search_path = public` — Supabase can't resolve `profiles` table in restricted execution context.
Fix: Recreated function with `set search_path = public`. Run in Supabase SQL Editor:
```sql
create or replace function handle_new_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into profiles (id, full_name, phone)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), new.raw_user_meta_data->>'phone');
  return new;
end;
$$;
```
Result: Fixed. Applied to live Supabase project.
Related files: `supabase/migrations/006_system.sql` (original, missing search_path)
Note: Always add `set search_path = public` to any `security definer` function in Supabase.

---

## Bug: Login succeeds but app stays on login screen
Status: Fixed

Symptoms: No error after login, but no navigation occurs.
Cause: `createRouter(ref)` called inside `SuqApp.build()` — new `GoRouter` created on every rebuild. Auth notifier fired on old instance; new instance never received it.
Fix: Converted `SuqApp` to `ConsumerStatefulWidget`. Router cached as `late final appRouter = createRouter()` in `_SuqAppState`. Router now created exactly once.
Result: Fixed.
Related files: `suq/lib/app.dart`, `suq/lib/shared/router/app_router.dart`
Note: Never instantiate `GoRouter` inside a `build()` method.

---

## Bug: `app_routes.dart` part-of import error
Status: Fixed

Symptoms: `flutter analyze` — "imported library can't have a part-of directive". `AppRoutes` undefined everywhere.
Cause: `app_routes.dart` had `part of 'app_router.dart'`; screens imported it directly as a library.
Fix: Removed `part of` directive. Made it a standalone file. Changed `app_router.dart` to `import 'app_routes.dart'`.
Result: Fixed.
Related files: `suq/lib/shared/router/app_routes.dart`, `suq/lib/shared/router/app_router.dart`
