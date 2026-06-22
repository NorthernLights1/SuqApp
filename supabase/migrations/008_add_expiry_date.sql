-- Add optional expiry_date to inventory (per branch-product stock entry)
-- Expiry is per current batch/stock, not per product type.
alter table inventory
  add column if not exists expiry_date date;
