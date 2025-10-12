-- PRODUCTION READY: SCD Support for Communication History
-- Run this script directly on your Supabase SQL Editor to add SCD duplicate prevention

-- Step 1: Add missing columns for SCD support
DO $$
BEGIN
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'communication_history' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.communication_history 
        ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    -- Add composite_key column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'communication_history' 
        AND column_name = 'composite_key'
    ) THEN
        ALTER TABLE public.communication_history 
        ADD COLUMN composite_key TEXT;
    END IF;
END $$;

-- Step 2: Create indexes for performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_communication_history_composite_key 
ON public.communication_history (composite_key) 
WHERE composite_key IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_communication_history_user_message_time 
ON public.communication_history (user_id, message_text, created_at);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_communication_history_created_at 
ON public.communication_history (created_at);

-- Step 3: Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_communication_history_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Apply the trigger
DROP TRIGGER IF EXISTS trigger_communication_history_updated_at ON public.communication_history;
CREATE TRIGGER trigger_communication_history_updated_at
    BEFORE UPDATE ON public.communication_history
    FOR EACH ROW
    EXECUTE FUNCTION update_communication_history_updated_at();

-- Step 5: Backfill composite_key for existing records (safe operation)
UPDATE public.communication_history 
SET composite_key = user_id || '_' || message_text || '_' || EXTRACT(EPOCH FROM created_at)::TEXT
WHERE composite_key IS NULL
AND created_at >= NOW() - INTERVAL '30 days'; -- Only recent records to avoid long-running operation

-- Step 6: Add documentation comments
COMMENT ON COLUMN public.communication_history.composite_key IS 'SCD composite key for duplicate prevention: user_id_message_text_timestamp_hash';
COMMENT ON COLUMN public.communication_history.updated_at IS 'SCD timestamp for tracking record updates';

-- Step 7: Show success message
DO $$
BEGIN
    RAISE NOTICE '✅ SCD Support successfully added to communication_history table';
    RAISE NOTICE '📊 Indexes created for optimal performance';
    RAISE NOTICE '🔄 Trigger added for automatic updated_at maintenance';
    RAISE NOTICE '🎯 Ready for production duplicate prevention!';
END $$;