-- Apply only the user_favorites table enhancements
-- Add new columns to user_favorites table for clean favorites storage
ALTER TABLE public.user_favorites 
ADD COLUMN IF NOT EXISTS symbol_label TEXT,
ADD COLUMN IF NOT EXISTS symbol_data JSONB,
ADD COLUMN IF NOT EXISTS is_custom BOOLEAN DEFAULT false;

-- Update the unique constraint to allow flexible symbol storage
-- Drop the old constraint that required symbol_id to reference symbols table
ALTER TABLE public.user_favorites 
DROP CONSTRAINT IF EXISTS user_favorites_symbol_id_fkey;

-- Create new index for performance on user-specific queries
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id_added ON public.user_favorites(user_id, added_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_custom ON public.user_favorites(user_id, is_custom);

-- Add comment for clarity
COMMENT ON TABLE public.user_favorites IS 'Stores user favorites for both default and custom symbols with complete symbol data and proper user isolation';
COMMENT ON COLUMN public.user_favorites.symbol_label IS 'Symbol label for easy retrieval and display';
COMMENT ON COLUMN public.user_favorites.symbol_data IS 'Complete symbol data stored as JSON for offline-first functionality';  
COMMENT ON COLUMN public.user_favorites.is_custom IS 'Indicates if this is a custom user-created symbol (true) or default symbol (false)';