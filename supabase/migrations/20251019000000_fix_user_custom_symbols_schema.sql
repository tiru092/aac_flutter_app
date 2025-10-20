-- Migration: Fix user_custom_symbols table schema
-- Description: Create correct user_custom_symbols table with proper UUID schema

-- Drop existing tables if they exist with wrong schema
DROP TABLE IF EXISTS public.user_custom_symbols CASCADE;
DROP TABLE IF EXISTS public.user_custom_categories CASCADE;

-- Create user_custom_categories table first (since symbols references it)
CREATE TABLE public.user_custom_categories (
  id uuid not null default gen_random_uuid (),
  profile_id uuid null,
  name text not null,
  icon_path text null,
  color_code integer not null,
  is_default boolean null default false,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint user_custom_categories_pkey primary key (id),
  constraint user_custom_categories_profile_id_name_key unique (profile_id, name),
  constraint user_custom_categories_profile_id_fkey foreign key (profile_id) references user_profiles (id) on delete CASCADE
) TABLESPACE pg_default;

-- Create user_custom_symbols table with correct schema
CREATE TABLE public.user_custom_symbols (
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
) TABLESPACE pg_default;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_custom_symbols_profile ON public.user_custom_symbols USING btree (profile_id, usage_count desc) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_custom_symbols_category ON public.user_custom_symbols USING btree (category_id) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_custom_categories_profile ON public.user_custom_categories USING btree (profile_id) TABLESPACE pg_default;

-- Create or replace the updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_custom_symbols_updated_at 
    BEFORE UPDATE ON user_custom_symbols 
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at ();

CREATE TRIGGER update_custom_categories_updated_at 
    BEFORE UPDATE ON user_custom_categories 
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at ();

-- Enable Row Level Security
ALTER TABLE user_custom_symbols ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_custom_categories ENABLE ROW LEVEL SECURITY;

-- RLS policies for user_custom_symbols
CREATE POLICY "Users can view own custom symbols" ON user_custom_symbols
    FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own custom symbols" ON user_custom_symbols
    FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own custom symbols" ON user_custom_symbols
    FOR UPDATE USING (profile_id = auth.uid());

CREATE POLICY "Users can delete own custom symbols" ON user_custom_symbols
    FOR DELETE USING (profile_id = auth.uid());

-- RLS policies for user_custom_categories  
CREATE POLICY "Users can view own custom categories" ON user_custom_categories
    FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own custom categories" ON user_custom_categories
    FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own custom categories" ON user_custom_categories
    FOR UPDATE USING (profile_id = auth.uid());

CREATE POLICY "Users can delete own custom categories" ON user_custom_categories
    FOR DELETE USING (profile_id = auth.uid());