-- Add Comprehensive AAC Features to Existing Database
-- Created: 2025-10-07
-- Description: Extends existing AAC schema with advanced features

-- ============================================================================
-- 1. ENHANCE EXISTING TABLES (ADD MISSING COLUMNS)
-- ============================================================================

-- Add versioning and metadata to existing user_profiles if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'user_profiles' AND column_name = 'version') THEN
        ALTER TABLE public.user_profiles ADD COLUMN version INTEGER DEFAULT 1;
        ALTER TABLE public.user_profiles ADD COLUMN synced_at TIMESTAMPTZ;
        ALTER TABLE public.user_profiles ADD COLUMN device_id TEXT;
        ALTER TABLE public.user_profiles ADD COLUMN last_login_at TIMESTAMPTZ;
        ALTER TABLE public.user_profiles ADD COLUMN is_primary BOOLEAN DEFAULT true;
    END IF;
END $$;

-- ============================================================================
-- 2. NEW TABLES FOR ADVANCED FEATURES  
-- ============================================================================

-- Phrase templates for quick communication
CREATE TABLE IF NOT EXISTS public.phrase_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    template_name TEXT NOT NULL,
    phrase_pattern TEXT NOT NULL, -- "I want [item] please"
    symbols_sequence JSONB, -- Ordered array of symbols
    category TEXT DEFAULT 'general',
    usage_count INTEGER DEFAULT 0,
    is_system_template BOOLEAN DEFAULT false,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(profile_id, template_name)
);

-- User-created custom categories
CREATE TABLE IF NOT EXISTS public.user_custom_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    icon_path TEXT, -- Supabase Storage path
    icon_url TEXT, -- CDN URL for performance
    color_code INTEGER,
    sort_order INTEGER DEFAULT 0,
    parent_category_id UUID REFERENCES public.user_custom_categories(id),
    is_shared BOOLEAN DEFAULT false,
    symbols_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(profile_id, name)
);

-- User-created custom symbols  
CREATE TABLE IF NOT EXISTS public.user_custom_symbols (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    description TEXT,
    image_path TEXT, -- Supabase Storage path
    image_url TEXT, -- CDN URL for performance
    category_id UUID REFERENCES public.user_custom_categories(id),
    speech_text TEXT,
    color_code INTEGER,
    tags TEXT[], -- For search and organization
    is_shared BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(profile_id, label)
);

-- Comprehensive user settings
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    setting_group TEXT NOT NULL, -- 'ui', 'speech', 'accessibility', 'privacy'
    setting_key TEXT NOT NULL,
    setting_value JSONB NOT NULL,
    is_locked BOOLEAN DEFAULT false, -- Caregiver can lock certain settings
    sync_priority INTEGER DEFAULT 1, -- 1=high, 5=low priority for sync
    last_modified_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(profile_id, setting_group, setting_key)
);

-- Learning progress tracking
CREATE TABLE IF NOT EXISTS public.learning_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    metric_type TEXT CHECK (metric_type IN ('symbols_learned', 'phrases_built', 'session_duration', 'accuracy_rate')) NOT NULL,
    metric_value DECIMAL(10,2) NOT NULL,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    context JSONB, -- Additional metadata
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Session tracking for usage patterns
CREATE TABLE IF NOT EXISTS public.app_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    session_start TIMESTAMPTZ DEFAULT NOW(),
    session_end TIMESTAMPTZ,
    duration_minutes INTEGER,
    symbols_used INTEGER DEFAULT 0,
    phrases_created INTEGER DEFAULT 0,
    device_info JSONB,
    app_version TEXT
);

-- Shared symbol libraries
CREATE TABLE IF NOT EXISTS public.shared_libraries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    creator_profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    library_name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    symbols_data JSONB, -- Array of symbol definitions
    downloads_count INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.0,
    is_verified BOOLEAN DEFAULT false, -- Reviewed by moderators
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 3. INDEXES FOR PERFORMANCE
-- ============================================================================

-- User profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_created ON public.user_profiles(created_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_version ON public.user_profiles(version);

-- Favorites indexes (using existing user_id column)
CREATE INDEX IF NOT EXISTS idx_favorites_user_symbol ON public.user_favorites(user_id, symbol_id);

-- Communication history indexes (using existing user_id column)
CREATE INDEX IF NOT EXISTS idx_communication_history_user_date ON public.communication_history(user_id, created_at DESC);

-- Custom content indexes
CREATE INDEX IF NOT EXISTS idx_custom_categories_profile ON public.user_custom_categories(profile_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_custom_symbols_profile ON public.user_custom_symbols(profile_id, usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_custom_symbols_category ON public.user_custom_symbols(category_id);

-- Settings indexes
CREATE INDEX IF NOT EXISTS idx_user_settings_profile_group ON public.user_settings(profile_id, setting_group);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_learning_analytics_profile_type ON public.learning_analytics(profile_id, metric_type);
CREATE INDEX IF NOT EXISTS idx_learning_analytics_period ON public.learning_analytics(period_start, period_end);

-- Session indexes
CREATE INDEX IF NOT EXISTS idx_app_sessions_profile_start ON public.app_sessions(profile_id, session_start DESC);

-- Shared libraries indexes
CREATE INDEX IF NOT EXISTS idx_shared_libraries_category ON public.shared_libraries(category);
CREATE INDEX IF NOT EXISTS idx_shared_libraries_rating ON public.shared_libraries(rating DESC);

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on new tables
ALTER TABLE public.phrase_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_custom_categories ENABLE ROW LEVEL SECURITY;  
ALTER TABLE public.user_custom_symbols ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_libraries ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. RLS POLICIES
-- ============================================================================

-- Phrase templates policies
CREATE POLICY "Users can manage their phrase templates" ON public.phrase_templates
    FOR ALL USING (
        profile_id IN (
            SELECT id FROM public.user_profiles 
            WHERE auth.uid() = auth.uid() -- User can access their profiles
        )
    );

-- Custom categories policies  
CREATE POLICY "Users can manage their custom categories" ON public.user_custom_categories
    FOR ALL USING (
        profile_id IN (
            SELECT id FROM public.user_profiles 
            WHERE auth.uid() = auth.uid()
        )
    );

-- Custom symbols policies
CREATE POLICY "Users can manage their custom symbols" ON public.user_custom_symbols
    FOR ALL USING (
        profile_id IN (
            SELECT id FROM public.user_profiles 
            WHERE auth.uid() = auth.uid()
        )
    );

-- Settings policies
CREATE POLICY "Users can manage their settings" ON public.user_settings
    FOR ALL USING (
        profile_id IN (
            SELECT id FROM public.user_profiles 
            WHERE auth.uid() = auth.uid()
        )
    );

-- Analytics policies
CREATE POLICY "Users can view their analytics" ON public.learning_analytics
    FOR SELECT USING (
        profile_id IN (
            SELECT id FROM public.user_profiles 
            WHERE auth.uid() = auth.uid()
        )
    );

-- Sessions policies
CREATE POLICY "Users can view their sessions" ON public.app_sessions
    FOR ALL USING (
        profile_id IN (
            SELECT id FROM public.user_profiles 
            WHERE auth.uid() = auth.uid()
        )
    );

-- Shared libraries policies
CREATE POLICY "Everyone can view verified shared libraries" ON public.shared_libraries
    FOR SELECT USING (is_verified = true);

CREATE POLICY "Users can manage their shared libraries" ON public.shared_libraries
    FOR ALL USING (
        creator_profile_id IN (
            SELECT id FROM public.user_profiles 
            WHERE auth.uid() = auth.uid()
        )
    );

-- ============================================================================
-- 6. TRIGGERS FOR UPDATED_AT
-- ============================================================================

-- Create updated_at trigger function if not exists
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables with updated_at columns
CREATE OR REPLACE TRIGGER update_custom_categories_updated_at 
    BEFORE UPDATE ON public.user_custom_categories 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER update_custom_symbols_updated_at 
    BEFORE UPDATE ON public.user_custom_symbols 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER update_shared_libraries_updated_at 
    BEFORE UPDATE ON public.shared_libraries 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 7. INITIAL DATA SETUP
-- ============================================================================

-- Insert default system phrase templates
INSERT INTO public.phrase_templates (
    profile_id, template_name, phrase_pattern, symbols_sequence, 
    category, is_system_template
) SELECT 
    p.id,
    template.name,
    template.pattern,
    template.sequence::jsonb,
    template.category,
    true
FROM public.user_profiles p
CROSS JOIN (VALUES 
    ('Basic Need', 'I want [item]', '["I", "want", "[item]"]', 'basic'),
    ('Greeting', 'Hello [person]', '["Hello", "[person]"]', 'social'),
    ('Thank You', 'Thank you [person]', '["Thank", "you", "[person]"]', 'social'),
    ('Help Request', 'I need help with [task]', '["I", "need", "help", "with", "[task]"]', 'basic'),
    ('Feeling', 'I feel [emotion]', '["I", "feel", "[emotion]"]', 'emotions')
) AS template(name, pattern, sequence, category)
ON CONFLICT (profile_id, template_name) DO NOTHING;
