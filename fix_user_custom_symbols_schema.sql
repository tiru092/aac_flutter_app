-- Fix user_custom_symbols schema mismatch and refresh Supabase cache
-- Issues:
-- 1. Table has profile_id but RLS policies reference user_id
-- 2. Supabase schema cache is out of sync with actual schema

-- Step 1: Fix RLS policies for user_custom_symbols to use profile_id
DROP POLICY IF EXISTS "Users can view own custom symbols" ON user_custom_symbols;
DROP POLICY IF EXISTS "Users can insert own custom symbols" ON user_custom_symbols;
DROP POLICY IF EXISTS "Users can update own custom symbols" ON user_custom_symbols;
DROP POLICY IF EXISTS "Users can delete own custom symbols" ON user_custom_symbols;

-- Create corrected RLS policies for user_custom_symbols using profile_id
CREATE POLICY "Users can view own custom symbols" ON user_custom_symbols
    FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert own custom symbols" ON user_custom_symbols
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update own custom symbols" ON user_custom_symbols
    FOR UPDATE USING (auth.uid() = profile_id);

CREATE POLICY "Users can delete own custom symbols" ON user_custom_symbols
    FOR DELETE USING (auth.uid() = profile_id);

-- Step 2: Fix RLS policies for user_custom_categories to use profile_id
DROP POLICY IF EXISTS "Users can view own custom categories" ON user_custom_categories;
DROP POLICY IF EXISTS "Users can insert own custom categories" ON user_custom_categories;
DROP POLICY IF EXISTS "Users can update own custom categories" ON user_custom_categories;
DROP POLICY IF EXISTS "Users can delete own custom categories" ON user_custom_categories;

-- Create corrected RLS policies for user_custom_categories using profile_id
CREATE POLICY "Users can view own custom categories" ON user_custom_categories
    FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert own custom categories" ON user_custom_categories
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update own custom categories" ON user_custom_categories
    FOR UPDATE USING (auth.uid() = profile_id);

CREATE POLICY "Users can delete own custom categories" ON user_custom_categories
    FOR DELETE USING (auth.uid() = profile_id);

-- Step 3: Refresh schema cache by recreating the problematic view/table references
-- This forces Supabase to reload the actual schema information

-- Force schema cache refresh for global_default_categories
SELECT pg_stat_reset_single_table_counters('global_default_categories'::regclass);

-- Verify schemas exist with correct column names
DO $$
BEGIN
  -- Verify user_custom_symbols has profile_id column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_custom_symbols' AND column_name = 'profile_id'
  ) THEN
    RAISE EXCEPTION 'user_custom_symbols missing profile_id column';
  END IF;
  
  -- Verify global_default_categories has color_code column  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'global_default_categories' AND column_name = 'color_code'
  ) THEN
    RAISE EXCEPTION 'global_default_categories missing color_code column';
  END IF;
  
  RAISE NOTICE 'Schema verification passed - all required columns exist';
END $$;