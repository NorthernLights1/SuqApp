-- 017_credit_payments.sql
-- Per-credit-sale payment history, enabling PARTIAL settlement with an audit
-- trail (each installment is a timestamped row — useful for dispute resolution).
--
-- A credit sale is "settled" when the sum of its credit_payments reaches the
-- sale total (at which point sales.credit_settled_at is stamped). Remaining on
-- a bill = sales.total - sum(credit_payments.amount).
--
-- RLS mirrors the discounts/refunds pattern: access is gated through the parent
-- sale's branch -> shop membership.

create table credit_payments (
  id          uuid primary key default gen_random_uuid(),
  sale_id     uuid not null references sales(id) on delete cascade,
  customer_id uuid references customers(id) on delete set null,
  amount      numeric(15,4) not null check (amount > 0),
  method      text not null check (method in ('cash','bank_transfer')),
  notes       text,
  recorded_by uuid references profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);

create index credit_payments_sale_id_idx     on credit_payments(sale_id);
create index credit_payments_customer_id_idx on credit_payments(customer_id);

alter table credit_payments enable row level security;

create policy "credit_payments_select" on credit_payments for select
  using (exists (
    select 1 from sales s
    where s.id = sale_id and private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  ));

create policy "credit_payments_insert" on credit_payments for insert
  with check (exists (
    select 1 from sales s
    where s.id = sale_id and private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  ));

-- service_role is server-only (Edge Functions); see migration 013.
grant select, insert, update, delete on credit_payments to service_role;
