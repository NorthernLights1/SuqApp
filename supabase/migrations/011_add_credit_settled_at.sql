-- Add credit reconciliation to sales
-- Null means the credit sale has not been settled yet.
-- Set to a timestamp when the customer pays for the specific sale.
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS credit_settled_at timestamptz;
