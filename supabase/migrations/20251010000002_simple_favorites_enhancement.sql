-- Simple favorites enhancement - minimal migration
-- Just add the essential columns needed for clean favorites storage

-- Add new columns to user_favorites table (ignore errors if they already exist)
DO $$ 
BEGIN
    -- Add symbol_label column
    BEGIN
        ALTER TABLE public.user_favorites ADD COLUMN symbol_label TEXT;
    EXCEPTION 
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add symbol_data column  
    BEGIN
        ALTER TABLE public.user_favorites ADD COLUMN symbol_data JSONB;
    EXCEPTION 
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add is_custom column
    BEGIN
        ALTER TABLE public.user_favorites ADD COLUMN is_custom BOOLEAN DEFAULT false;
    EXCEPTION 
        WHEN duplicate_column THEN NULL;
    END;
END $$;

-- Create indexes (ignore if they exist)
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id_added ON public.user_favorites(user_id, added_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_custom ON public.user_favorites(user_id, is_custom);

-- Mark migration as complete
INSERT INTO supabase_migrations.schema_migrations (version) 
VALUES ('20251010000002') 
ON CONFLICT (version) DO NOTHING;