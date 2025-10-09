-- Initial AAC Flutter App Schema Migration
-- Creates all core tables, RLS policies, indexes, and triggers for the AAC communication app

-- Initial AAC Flutter App Schema Migration
-- Note: Using gen_random_uuid() which is available by default in Supabase

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- User profiles (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('caregiver', 'communicator', 'therapist', 'admin')) DEFAULT 'communicator',
    avatar_url TEXT,
    phone_number TEXT,
    pin_hash TEXT, -- For caregiver role authentication
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    settings JSONB DEFAULT '{}',
    app_settings JSONB DEFAULT '{}'
);

-- Categories for organizing symbols
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    color_code INTEGER,
    icon_path TEXT,
    is_default BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- Symbols for communication
CREATE TABLE IF NOT EXISTS public.symbols (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    label TEXT NOT NULL,
    image_path TEXT,
    speech_text TEXT,
    description TEXT,
    color_code INTEGER,
    is_default BOOLEAN DEFAULT false,
    is_favorite BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Communication history for tracking usage
CREATE TABLE IF NOT EXISTS public.communication_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    message_text TEXT NOT NULL,
    symbols_used JSONB DEFAULT '[]', -- Array of symbol IDs used
    communication_type TEXT DEFAULT 'phrase' CHECK (communication_type IN ('phrase', 'word', 'sentence')),
    context_info JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Phrase history for favorite phrases
CREATE TABLE IF NOT EXISTS public.phrase_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    text TEXT NOT NULL,
    is_favorite BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 1,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User favorites (symbols)
CREATE TABLE IF NOT EXISTS public.user_favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    symbol_id UUID REFERENCES public.symbols(id) ON DELETE CASCADE NOT NULL,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, symbol_id)
);

-- Profile sharing for caregivers/therapists
CREATE TABLE IF NOT EXISTS public.profile_shares (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    shared_with_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    permission_level TEXT NOT NULL CHECK (permission_level IN ('read', 'write', 'admin')) DEFAULT 'read',
    shared_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    message TEXT,
    UNIQUE(owner_id, shared_with_id)
);

-- User permissions system
CREATE TABLE IF NOT EXISTS public.user_permissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    permission_key TEXT NOT NULL,
    permission_value JSONB DEFAULT '{}',
    granted_by UUID REFERENCES auth.users(id),
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    UNIQUE(user_id, permission_key)
);

-- Subscriptions for premium features
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plan_type TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'cancelled', 'expired', 'trial')) DEFAULT 'trial',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    auto_renew BOOLEAN DEFAULT true,
    payment_provider TEXT,
    external_subscription_id TEXT,
    metadata JSONB DEFAULT '{}'
);

-- Payment transactions
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    subscription_id UUID REFERENCES public.subscriptions(id),
    amount_cents INTEGER NOT NULL,
    currency TEXT DEFAULT 'USD',
    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'refunded')) DEFAULT 'pending',
    payment_provider TEXT,
    external_transaction_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Sync state tracking for offline/online synchronization
CREATE TABLE IF NOT EXISTS public.sync_state (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    table_name TEXT NOT NULL,
    last_sync_at TIMESTAMPTZ DEFAULT NOW(),
    sync_version INTEGER DEFAULT 1,
    pending_changes JSONB DEFAULT '[]',
    UNIQUE(user_id, table_name)
);

-- Audit logs for security and compliance
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- App-wide default symbols and categories
CREATE TABLE IF NOT EXISTS public.app_defaults (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('symbol', 'category', 'phrase', 'setting')),
    name TEXT NOT NULL,
    data JSONB NOT NULL,
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User customizations of app defaults
CREATE TABLE IF NOT EXISTS public.user_default_customizations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    default_id UUID REFERENCES public.app_defaults(id) ON DELETE CASCADE NOT NULL,
    customized_data JSONB NOT NULL,
    is_hidden BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, default_id)
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.symbols ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communication_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phrase_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_defaults ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_default_customizations ENABLE ROW LEVEL SECURITY;

-- User profiles: Users can only access their own profile
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Categories: Users can only access their own categories
CREATE POLICY "Users can manage own categories" ON public.categories
    FOR ALL USING (auth.uid() = user_id);

-- Symbols: Users can access their own symbols + shared symbols
CREATE POLICY "Users can manage own symbols" ON public.symbols
    FOR ALL USING (auth.uid() = user_id);

-- Allow reading shared symbols
CREATE POLICY "Users can view shared symbols" ON public.symbols
    FOR SELECT USING (
        user_id IN (
            SELECT owner_id FROM public.profile_shares 
            WHERE shared_with_id = auth.uid() AND is_active = true
        )
    );

-- Communication history: Users can only access their own history
CREATE POLICY "Users can manage own communication history" ON public.communication_history
    FOR ALL USING (auth.uid() = user_id);

-- Phrase history: Users can only access their own phrases
CREATE POLICY "Users can manage own phrase history" ON public.phrase_history
    FOR ALL USING (auth.uid() = user_id);

-- User favorites: Users can only manage their own favorites
CREATE POLICY "Users can manage own favorites" ON public.user_favorites
    FOR ALL USING (auth.uid() = user_id);

-- Profile shares: Users can see shares they own or are shared with
CREATE POLICY "Users can view relevant profile shares" ON public.profile_shares
    FOR SELECT USING (auth.uid() = owner_id OR auth.uid() = shared_with_id);

CREATE POLICY "Users can manage own profile shares" ON public.profile_shares
    FOR ALL USING (auth.uid() = owner_id);

-- User permissions: Users can view their own permissions
CREATE POLICY "Users can view own permissions" ON public.user_permissions
    FOR SELECT USING (auth.uid() = user_id);

-- Subscriptions: Users can view their own subscriptions
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions
    FOR ALL USING (auth.uid() = user_id);

-- Payment transactions: Users can view their own transactions
CREATE POLICY "Users can view own transactions" ON public.payment_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- Sync state: Users can manage their own sync state
CREATE POLICY "Users can manage own sync state" ON public.sync_state
    FOR ALL USING (auth.uid() = user_id);

-- Audit logs: Users can view their own audit logs
CREATE POLICY "Users can view own audit logs" ON public.audit_logs
    FOR SELECT USING (auth.uid() = user_id);

-- App defaults: Everyone can read, only admins can modify
CREATE POLICY "Anyone can view app defaults" ON public.app_defaults
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage app defaults" ON public.app_defaults
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- User customizations: Users can manage their own customizations
CREATE POLICY "Users can manage own customizations" ON public.user_default_customizations
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Core table indexes
CREATE INDEX IF NOT EXISTS idx_symbols_user_id ON public.symbols(user_id);
CREATE INDEX IF NOT EXISTS idx_symbols_category_id ON public.symbols(category_id);
CREATE INDEX IF NOT EXISTS idx_symbols_is_favorite ON public.symbols(user_id, is_favorite) WHERE is_favorite = true;
CREATE INDEX IF NOT EXISTS idx_symbols_usage ON public.symbols(user_id, usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_symbols_last_used ON public.symbols(user_id, last_used_at DESC);

CREATE INDEX IF NOT EXISTS idx_categories_user_id ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON public.categories(user_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_communication_history_user_id ON public.communication_history(user_id);
CREATE INDEX IF NOT EXISTS idx_communication_history_created_at ON public.communication_history(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_phrase_history_user_id ON public.phrase_history(user_id);
CREATE INDEX IF NOT EXISTS idx_phrase_history_favorites ON public.phrase_history(user_id, is_favorite) WHERE is_favorite = true;
CREATE INDEX IF NOT EXISTS idx_phrase_history_usage ON public.phrase_history(user_id, last_used_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON public.user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_symbol_id ON public.user_favorites(symbol_id);

CREATE INDEX IF NOT EXISTS idx_profile_shares_owner ON public.profile_shares(owner_id);
CREATE INDEX IF NOT EXISTS idx_profile_shares_shared_with ON public.profile_shares(shared_with_id);
CREATE INDEX IF NOT EXISTS idx_profile_shares_active ON public.profile_shares(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_sync_state_user_table ON public.sync_state(user_id, table_name);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

-- App defaults indexes
CREATE INDEX IF NOT EXISTS idx_app_defaults_type ON public.app_defaults(type, is_active);
CREATE INDEX IF NOT EXISTS idx_user_customizations_user_id ON public.user_default_customizations(user_id);

-- ============================================================================
-- TRIGGERS AND FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to tables with updated_at columns
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
CREATE TRIGGER update_categories_updated_at 
    BEFORE UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_symbols_updated_at ON public.symbols;
CREATE TRIGGER update_symbols_updated_at 
    BEFORE UPDATE ON public.symbols
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_phrase_history_updated_at ON public.phrase_history;
CREATE TRIGGER update_phrase_history_updated_at 
    BEFORE UPDATE ON public.phrase_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_app_defaults_updated_at ON public.app_defaults;
CREATE TRIGGER update_app_defaults_updated_at 
    BEFORE UPDATE ON public.app_defaults
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_customizations_updated_at ON public.user_default_customizations;
CREATE TRIGGER update_user_customizations_updated_at 
    BEFORE UPDATE ON public.user_default_customizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Create storage bucket for user files (avatars, symbols, etc.)
INSERT INTO storage.buckets (id, name, public) VALUES ('user-files', 'user-files', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for user files
CREATE POLICY "Users can upload own files" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'user-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view own files" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'user-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can update own files" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'user-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete own files" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'user-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Create storage bucket for app defaults (symbols, icons, etc.)
INSERT INTO storage.buckets (id, name, public) VALUES ('app-defaults', 'app-defaults', true)
ON CONFLICT (id) DO NOTHING;

-- App defaults storage policies (public read, admin write)
CREATE POLICY "Anyone can view default files" ON storage.objects
    FOR SELECT USING (bucket_id = 'app-defaults');

CREATE POLICY "Admins can manage default files" ON storage.objects
    FOR ALL USING (
        bucket_id = 'app-defaults' AND
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
