-- Add SCD (Slowly Changing Dimensions) support to communication_history table
-- This enables proper duplicate prevention and merge operations

-- Add missing columns for SCD support
ALTER TABLE public.communication_history 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS composite_key TEXT;

-- Create unique index on composite_key for duplicate prevention
CREATE UNIQUE INDEX IF NOT EXISTS idx_communication_history_composite_key 
ON public.communication_history (composite_key) 
WHERE composite_key IS NOT NULL;

-- Create index for efficient duplicate checking queries
CREATE INDEX IF NOT EXISTS idx_communication_history_user_message_time 
ON public.communication_history (user_id, message_text, created_at);

-- Create index for time-based queries (cleanup and incremental sync)
CREATE INDEX IF NOT EXISTS idx_communication_history_created_at 
ON public.communication_history (created_at);

-- Update trigger to automatically set updated_at
CREATE OR REPLACE FUNCTION update_communication_history_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger
DROP trigger IF EXISTS trigger_communication_history_updated_at ON public.communication_history;
CREATE TRIGGER trigger_communication_history_updated_at
    BEFORE UPDATE ON public.communication_history
    FOR EACH ROW
    EXECUTE FUNCTION update_communication_history_updated_at();

-- Backfill composite_key for existing records (one-time operation)
UPDATE public.communication_history 
SET composite_key = user_id || '_' || message_text || '_' || EXTRACT(EPOCH FROM created_at)::TEXT
WHERE composite_key IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN public.communication_history.composite_key IS 'SCD composite key for duplicate prevention: user_id_message_text_timestamp_hash';
COMMENT ON COLUMN public.communication_history.updated_at IS 'SCD timestamp for tracking record updates';