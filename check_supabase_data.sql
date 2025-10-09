-- Check what tables and data actually exist in Supabase

-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check symbols table content
SELECT COUNT(*) as symbol_count FROM public.symbols;

-- Check categories table content  
SELECT COUNT(*) as category_count FROM public.categories;

-- Check storage buckets
SELECT * FROM storage.buckets;

-- Check if any default symbols exist
SELECT id, label, image_path, is_default 
FROM public.symbols 
WHERE is_default = true 
LIMIT 10;