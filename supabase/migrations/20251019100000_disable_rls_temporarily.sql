-- TEMPORARY: Disable RLS for debugging the "Junn" UUID issue
-- This should be reverted after the issue is resolved

-- Disable RLS temporarily
ALTER TABLE user_custom_symbols DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_custom_categories DISABLE ROW LEVEL SECURITY;

-- Add comment for tracking
COMMENT ON TABLE user_custom_symbols IS 'RLS DISABLED TEMPORARILY FOR DEBUGGING - MUST RE-ENABLE';
COMMENT ON TABLE user_custom_categories IS 'RLS DISABLED TEMPORARILY FOR DEBUGGING - MUST RE-ENABLE';