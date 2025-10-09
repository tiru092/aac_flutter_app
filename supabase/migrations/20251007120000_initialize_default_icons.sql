-- Initialize Default Icons - Global Defaults Table Approach
-- Create separate tables for global defaults that don't require user_id

-- Create global default categories table
CREATE TABLE IF NOT EXISTS public.global_default_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    color_code INTEGER,
    icon_path TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create global default symbols table  
CREATE TABLE IF NOT EXISTS public.global_default_symbols (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category_name TEXT NOT NULL,
    label TEXT NOT NULL,
    image_path TEXT NOT NULL,
    speech_text TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(label, category_name)
);

-- Insert default categories
INSERT INTO public.global_default_categories (name, color_code, sort_order) VALUES 
('Food & Drinks', 16744059, 1),
('Vehicles', 5164932, 2),
('Basic Needs', 5367910, 3),
('Emotions', 16776305, 4),
('Actions', 7106815, 5),
('Family', 16750915, 6)
ON CONFLICT (name) DO NOTHING;

-- Insert default symbols with local-first paths
INSERT INTO public.global_default_symbols (category_name, label, image_path, speech_text, description) VALUES 
('Food & Drinks', 'Apple', 'assets/symbols/Apple.png', 'Apple', 'Red apple fruit for eating'),
('Food & Drinks', 'Water', 'assets/symbols/Water.png', 'Water', 'Glass of water to drink'),
('Vehicles', 'Car', 'assets/symbols/Car.png', 'Car', 'Family car for transportation'),
('Emotions', 'Happy', 'emoji:😊', 'Happy', 'Feeling happy and joyful'),
('Actions', 'Eat', 'emoji:🍽️', 'Eat', 'Action of eating food'),
('Family', 'Mom', 'emoji:👩', 'Mom', 'Mother or female caregiver')
ON CONFLICT (label, category_name) DO NOTHING;