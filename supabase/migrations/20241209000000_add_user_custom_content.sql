-- Migration: Add user custom symbols and categories tables
-- Description: Create tables for user-specific custom content persistence

-- Create user_custom_symbols table for persisting custom symbols across app restarts
CREATE TABLE IF NOT EXISTS user_custom_symbols (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    image_path TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    speech_text TEXT,
    color_code INTEGER,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_custom_categories table for persisting custom categories across app restarts
CREATE TABLE IF NOT EXISTS user_custom_categories (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon_path TEXT,
    color_code INTEGER NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_custom_symbols_user_id ON user_custom_symbols(user_id);
CREATE INDEX IF NOT EXISTS idx_user_custom_symbols_category ON user_custom_symbols(category);
CREATE INDEX IF NOT EXISTS idx_user_custom_categories_user_id ON user_custom_categories(user_id);

-- Set up Row Level Security (RLS)
ALTER TABLE user_custom_symbols ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_custom_categories ENABLE ROW LEVEL SECURITY;

-- RLS policies for user_custom_symbols
CREATE POLICY IF NOT EXISTS "Users can view own custom symbols" ON user_custom_symbols
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can insert own custom symbols" ON user_custom_symbols
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update own custom symbols" ON user_custom_symbols
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can delete own custom symbols" ON user_custom_symbols
    FOR DELETE USING (auth.uid() = user_id);

-- RLS policies for user_custom_categories  
CREATE POLICY IF NOT EXISTS "Users can view own custom categories" ON user_custom_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can insert own custom categories" ON user_custom_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update own custom categories" ON user_custom_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can delete own custom categories" ON user_custom_categories
    FOR DELETE USING (auth.uid() = user_id);

-- Add automatic updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER IF NOT EXISTS update_user_custom_symbols_updated_at 
    BEFORE UPDATE ON user_custom_symbols 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER IF NOT EXISTS update_user_custom_categories_updated_at 
    BEFORE UPDATE ON user_custom_categories 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();