-- Check user_favorites table structure and data
SELECT * FROM user_favorites WHERE user_id = 'a2c90b93-2854-4ce6-960f-8708d0484aeb';

-- Check user_custom_categories table structure and data  
SELECT * FROM user_custom_categories WHERE user_id = 'a2c90b93-2854-4ce6-960f-8708d0484aeb';

-- Check user_custom_symbols table to see if favorites symbols were created
SELECT * FROM user_custom_symbols WHERE profile_id = 'a2c90b93-2854-4ce6-960f-8708d0484aeb';

-- Check communication_history to confirm history sync worked
SELECT COUNT(*) as history_count FROM communication_history WHERE user_id = 'a2c90b93-2854-4ce6-960f-8708d0484aeb';

-- Check if tables exist
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('user_favorites', 'user_custom_categories', 'user_custom_symbols', 'communication_history');