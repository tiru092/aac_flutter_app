-- Direct SQL script to create user_custom_symbols table
-- Run this directly in Supabase to bypass migration issues

-- First, create user_custom_categories table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_custom_categories (
  id uuid not null default gen_random_uuid (),
  profile_id uuid null,
  name text not null,
  icon_path text null,
  color_code integer not null,
  is_default boolean null default false,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint user_custom_categories_pkey primary key (id),
  constraint user_custom_categories_profile_id_name_key unique (profile_id, name)
);

-- Create user_custom_symbols table
CREATE TABLE IF NOT EXISTS public.user_custom_symbols (
  id uuid not null default gen_random_uuid (),
  profile_id uuid null,
  label text not null,
  description text null,
  image_path text null,
  image_url text null,
  category_id uuid null,
  speech_text text null,
  color_code integer null,
  tags text[] null,
  is_shared boolean null default false,
  usage_count integer null default 0,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint user_custom_symbols_pkey primary key (id),
  constraint user_custom_symbols_profile_id_label_key unique (profile_id, label),
  constraint user_custom_symbols_category_id_fkey foreign KEY (category_id) references user_custom_categories (id),
  constraint user_custom_symbols_profile_id_fkey foreign KEY (profile_id) references user_profiles (id) on delete CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_custom_symbols_profile ON public.user_custom_symbols USING btree (profile_id, usage_count desc);
CREATE INDEX IF NOT EXISTS idx_custom_symbols_category ON public.user_custom_symbols USING btree (category_id);
CREATE INDEX IF NOT EXISTS idx_custom_categories_profile ON public.user_custom_categories USING btree (profile_id);

-- Create or replace the updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_custom_symbols_updated_at ON user_custom_symbols;
CREATE TRIGGER update_custom_symbols_updated_at 
    BEFORE UPDATE ON user_custom_symbols 
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at ();

DROP TRIGGER IF EXISTS update_custom_categories_updated_at ON user_custom_categories;
CREATE TRIGGER update_custom_categories_updated_at 
    BEFORE UPDATE ON user_custom_categories 
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at ();

-- Verify table creation
SELECT 'user_custom_symbols table created successfully' as status;