-- Add selling_price to products
-- Price is optional (null = cashier sets it at time of sale)
alter table products
  add column if not exists selling_price numeric(15,4);
