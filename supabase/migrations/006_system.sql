-- ============================================================
-- Domain 6: System & Infrastructure
-- ============================================================

-- Key-value store for all shop configuration
create table shop_settings (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid not null references shops(id) on delete cascade,
  branch_id   uuid references branches(id) on delete cascade, -- null = shop-wide setting
  key         text not null,
  value       jsonb not null,
  updated_by  uuid not null references profiles(id),
  updated_at  timestamptz not null default now(),
  unique(shop_id, branch_id, key)
);

-- Abstracted notification channels
create table notification_channels (
  id            uuid primary key default gen_random_uuid(),
  code          text not null unique,
  name          text not null,
  is_active     boolean not null default true,
  config_schema jsonb not null default '{}'
);

create table notification_types (
  id               uuid primary key default gen_random_uuid(),
  code             text not null unique,
  name             text not null,
  default_template text
);

create table notification_configs (
  id                      uuid primary key default gen_random_uuid(),
  shop_id                 uuid not null references shops(id) on delete cascade,
  notification_type_id    uuid not null references notification_types(id),
  channel_id              uuid not null references notification_channels(id),
  is_enabled              boolean not null default true,
  threshold               jsonb not null default '{}',
  unique(shop_id, notification_type_id, channel_id)
);

create table notification_logs (
  id                      uuid primary key default gen_random_uuid(),
  shop_id                 uuid not null references shops(id) on delete cascade,
  notification_config_id  uuid references notification_configs(id) on delete set null,
  recipient               text not null,
  status                  text not null default 'pending' check (status in ('sent','failed','pending')),
  payload                 jsonb not null default '{}',
  sent_at                 timestamptz not null default now()
);

-- Export job tracking
create table export_jobs (
  id           uuid primary key default gen_random_uuid(),
  shop_id      uuid not null references shops(id) on delete cascade,
  branch_id    uuid references branches(id) on delete set null,
  requested_by uuid not null references profiles(id),
  format       text not null check (format in ('pdf','excel')),
  report_type  text not null check (report_type in ('sales','inventory','financial','expenses','full')),
  period_type  text not null check (period_type in ('daily','weekly','monthly','yearly','custom')),
  date_from    date not null,
  date_to      date not null,
  status       text not null default 'pending' check (status in ('pending','processing','completed','failed')),
  file_url     text,
  created_at   timestamptz not null default now(),
  completed_at timestamptz
);

-- Offline sync tracking
create table sync_logs (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references profiles(id),
  branch_id      uuid not null references branches(id),
  device_id      text not null,
  last_synced_at timestamptz not null default now(),
  status         text not null default 'success'
);

-- ============================================================
-- Seed: Notification channels
-- ============================================================
insert into notification_channels (code, name, is_active) values
  ('email', 'Email',         true),
  ('sms',   'SMS',           false),
  ('push',  'Push Notification', false);

-- ============================================================
-- Seed: Notification types
-- ============================================================
insert into notification_types (code, name, default_template) values
  ('low_stock',               'Low Stock Alert',            'Product {{product}} is running low ({{quantity}} {{unit}} remaining).'),
  ('sync_warning',            'Sync Warning',               'Your app has not synced in over {{hours}} hours.'),
  ('debt_reminder',           'Credit Debt Reminder',       'Customer {{customer}} has an outstanding balance of {{amount}}.'),
  ('reconciliation_reminder', 'Reconciliation Reminder',    'Daily cash reconciliation for {{branch}} has not been completed.');

-- ============================================================
-- RLS Policies
-- ============================================================
alter table shop_settings         enable row level security;
alter table notification_channels enable row level security;
alter table notification_types    enable row level security;
alter table notification_configs  enable row level security;
alter table notification_logs     enable row level security;
alter table export_jobs           enable row level security;
alter table sync_logs             enable row level security;

create policy "shop_settings_select" on shop_settings for select using (is_shop_member(shop_id));
create policy "shop_settings_write"  on shop_settings for all   using (is_shop_member(shop_id));

create policy "notification_channels_select" on notification_channels for select using (auth.uid() is not null);
create policy "notification_types_select"    on notification_types    for select using (auth.uid() is not null);

create policy "notification_configs_select" on notification_configs for select using (is_shop_member(shop_id));
create policy "notification_configs_write"  on notification_configs for all   using (is_shop_member(shop_id));

create policy "notification_logs_select" on notification_logs for select using (is_shop_member(shop_id));

create policy "export_jobs_select" on export_jobs for select using (is_shop_member(shop_id));
create policy "export_jobs_write"  on export_jobs for all   using (is_shop_member(shop_id));

create policy "sync_logs_select" on sync_logs for select using (user_id = auth.uid());
create policy "sync_logs_write"  on sync_logs for all   using (user_id = auth.uid());

-- ============================================================
-- Function: auto-create profile on signup
-- ============================================================
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.raw_user_meta_data->>'phone'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
