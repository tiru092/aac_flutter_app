-- Initialize Default Icons in Supabase Database
-- This creates the database records for local-first + Supabase sync architecture

-- First, create default categories
INSERT INTO public.categories (id, user_id, name, color_code, is_default, sort_order, created_at, updated_at) VALUES 
(gen_random_uuid(), gen_random_uuid(), 'Food & Drinks', 16744059, true, 1, NOW(), NOW()),
(gen_random_uuid(), gen_random_uuid(), 'Vehicles', 5164932, true, 2, NOW(), NOW()),
(gen_random_uuid(), gen_random_uuid(), 'Basic Needs', 5367910, true, 3, NOW(), NOW())
ON CONFLICT (user_id, name) DO NOTHING;

-- Get the category IDs for reference
WITH category_refs AS (
    SELECT id, name FROM public.categories WHERE is_default = true
),
food_category AS (SELECT id FROM category_refs WHERE name = 'Food & Drinks'),
vehicle_category AS (SELECT id FROM category_refs WHERE name = 'Vehicles')

-- Insert default symbols with both local and remote paths for local-first architecture
INSERT INTO public.symbols (id, user_id, category_id, label, image_path, speech_text, description, is_default, usage_count, created_at, updated_at) 
SELECT 
    gen_random_uuid(),
    gen_random_uuid(), -- Will be updated to use proper user_id in app
    food_category.id,
    'Apple',
    'assets/symbols/Apple.png', -- Local-first path
    'Apple',
    'Red apple fruit for eating',
    true,
    0,
    NOW(),
    NOW()
FROM food_category

UNION ALL

SELECT 
    gen_random_uuid(),
    gen_random_uuid(),
    food_category.id,
    'Water',
    'assets/symbols/Water.png', -- Local-first path
    'Water',
    'Glass of water to drink',
    true,
    0,
    NOW(),
    NOW()
FROM food_category

UNION ALL

SELECT 
    gen_random_uuid(),
    gen_random_uuid(),
    vehicle_category.id,
    'Car',
    'assets/symbols/Car.png', -- Local-first path
    'Car',
    'Family car for transportation',
    true,
    0,
    NOW(),
    NOW()
FROM vehicle_category

ON CONFLICT DO NOTHING;