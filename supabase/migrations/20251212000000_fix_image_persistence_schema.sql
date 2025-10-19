-- Fix schema issues for image persistence
-- Date: 2025-01-12
-- Purpose: Fix RLS policies and add missing fields for custom symbols persistence

-- Fix user_custom_symbols table - ensure it has proper fields for image persistence
CREATE TABLE IF NOT EXISTS user_custom_symbols (
    id TEXT PRIMARY KEY,
    profile_id UUID NOT NULL,
    label TEXT NOT NULL,
    image_path TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Custom',
    description TEXT,
    speech_text TEXT,
    color_code INTEGER DEFAULT 0xFF6C63FF,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fix user_custom_categories table
CREATE TABLE IF NOT EXISTS user_custom_categories (
    id TEXT PRIMARY KEY,
    profile_id UUID NOT NULL,
    name TEXT NOT NULL,
    icon_path TEXT,
    color_code INTEGER NOT NULL DEFAULT 0xFF6C63FF,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_custom_symbols ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_custom_categories ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view own custom symbols" ON user_custom_symbols;
DROP POLICY IF EXISTS "Users can insert own custom symbols" ON user_custom_symbols;
DROP POLICY IF EXISTS "Users can update own custom symbols" ON user_custom_symbols;
DROP POLICY IF EXISTS "Users can delete own custom symbols" ON user_custom_symbols;

DROP POLICY IF EXISTS "Users can view own custom categories" ON user_custom_categories;
DROP POLICY IF EXISTS "Users can insert own custom categories" ON user_custom_categories;
DROP POLICY IF EXISTS "Users can update own custom categories" ON user_custom_categories;
DROP POLICY IF EXISTS "Users can delete own custom categories" ON user_custom_categories;

-- Create correct RLS policies using profile_id
CREATE POLICY "Users can view own custom symbols" ON user_custom_symbols
    FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert own custom symbols" ON user_custom_symbols
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update own custom symbols" ON user_custom_symbols
    FOR UPDATE USING (auth.uid() = profile_id);

CREATE POLICY "Users can delete own custom symbols" ON user_custom_symbols
    FOR DELETE USING (auth.uid() = profile_id);

CREATE POLICY "Users can view own custom categories" ON user_custom_categories
    FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert own custom categories" ON user_custom_categories
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update own custom categories" ON user_custom_categories
    FOR UPDATE USING (auth.uid() = profile_id);

CREATE POLICY "Users can delete own custom categories" ON user_custom_categories
    FOR DELETE USING (auth.uid() = profile_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_custom_symbols_profile_id ON user_custom_symbols(profile_id);
CREATE INDEX IF NOT EXISTS idx_user_custom_symbols_category ON user_custom_symbols(category);
CREATE INDEX IF NOT EXISTS idx_user_custom_categories_profile_id ON user_custom_categories(profile_id);

-- Fix global_default_categories table to ensure color_code column exists
ALTER TABLE global_default_categories ADD COLUMN IF NOT EXISTS color_code INTEGER DEFAULT 0xFF6C63FF;

-- Create update triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_user_custom_symbols_updated_at ON user_custom_symbols;
CREATE TRIGGER update_user_custom_symbols_updated_at 
    BEFORE UPDATE ON user_custom_symbols 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_custom_categories_updated_at ON user_custom_categories;
CREATE TRIGGER update_user_custom_categories_updated_at 
    BEFORE UPDATE ON user_custom_categories 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();