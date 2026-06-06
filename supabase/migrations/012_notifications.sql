-- ============================================================
-- Migration 012: Notification system updates
-- ============================================================

-- Add Telegram as a notification channel (inactive — not yet implemented)
INSERT INTO notification_channels (code, name, is_active)
VALUES ('telegram', 'Telegram', false)
ON CONFLICT (code) DO UPDATE SET is_active = false;

-- Add credit_settlement_method + notes columns (if not already added by another session)
ALTER TABLE public.sales
  ADD COLUMN IF NOT EXISTS credit_settlement_method text,
  ADD COLUMN IF NOT EXISTS credit_settlement_notes text;

-- Add constraint separately so it applies even when the column already existed before this migration
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'sales_credit_settlement_method_check'
      AND conrelid = 'public.sales'::regclass
  ) THEN
    ALTER TABLE public.sales
      ADD CONSTRAINT sales_credit_settlement_method_check
        CHECK (credit_settlement_method IN ('cash', 'bank_transfer'));
  END IF;
END $$;
