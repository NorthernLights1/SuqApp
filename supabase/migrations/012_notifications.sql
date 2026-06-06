-- ============================================================
-- Migration 012: Notification system updates
-- ============================================================

-- Add Telegram as a notification channel
INSERT INTO notification_channels (code, name, is_active)
VALUES ('telegram', 'Telegram', true)
ON CONFLICT (code) DO NOTHING;

-- Add credit_settlement_method + notes columns (if not already added by another session)
ALTER TABLE public.sales
  ADD COLUMN IF NOT EXISTS credit_settlement_method text
    CHECK (credit_settlement_method IN ('cash', 'bank_transfer')),
  ADD COLUMN IF NOT EXISTS credit_settlement_notes text;
