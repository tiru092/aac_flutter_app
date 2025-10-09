# Supabase Setup & Migration Plan
## Phase-by-Phase Implementation Without Breaking Existing Code

### 🎯 **Migration Strategy Overview**

**Key Principle**: Set up Supabase infrastructure completely BEFORE touching any existing code. Build parallel services, then gradually migrate.

---

## **Phase 1: Development Environment Setup** ⚙️

### Step 1.1: Install Supabase CLI Tools
```powershell
# Option A: NPM (recommended for this project)
npm install -g supabase

# Option B: Chocolatey (if available)
choco install supabase

# Option C: Download binary directly
# Download from: https://github.com/supabase/cli/releases
```

### Step 1.2: Verify Installation
```powershell
supabase --version
supabase help
```

### Step 1.3: Configure VSCode for Supabase
```powershell
# Install VSCode extensions
code --install-extension supabase.supabase-vscode
code --install-extension ms-vscode.vscode-postgresql
```

**🎯 Goal**: Have working Supabase CLI and VSCode integration ready.

---

## **Phase 2: Supabase Project Creation** 🏗️

### Step 2.1: Create Online Supabase Project
1. **Go to**: https://supabase.com/dashboard
2. **Sign up/Login** with GitHub or email
3. **Create New Project**:
   - Organization: Create new or use existing
   - Project Name: `aac-flutter-app`
   - Database Password: Generate strong password (save securely)
   - Region: Choose closest to your users
4. **Wait** for project creation (~2 minutes)

### Step 2.2: Get Project Credentials
1. **Go to**: Project Settings → API
2. **Copy and save**:
   - Project URL
   - Project Reference ID
   - anon public key
   - service_role secret key (keep secure!)

### Step 2.3: Initialize Local Supabase Project
```powershell
# In your project directory
cd "C:\Users\PC\Documents\AAC_Arjun_app\aac_flutter_app"

# Initialize Supabase locally
supabase init

# Link to your online project
supabase link --project-ref YOUR_PROJECT_REF
```

**🎯 Goal**: Working Supabase project (online + local) linked and ready.

---

## **Phase 3: Database Schema Deployment** 📊

### Step 3.1: Create Migration File
```powershell
# Create initial migration
supabase migration new initial_aac_schema
```

### Step 3.2: Add Schema to Migration
- Copy the complete schema from our previous analysis
- Include all 14 tables, RLS policies, indexes, triggers
- Add storage bucket configurations

### Step 3.3: Deploy Schema
```powershell
# Deploy to your online project
supabase db push

# Verify deployment
supabase db pull --schema-only
```

### Step 3.4: Verify in Dashboard
1. **Go to**: Supabase Dashboard → Table Editor
2. **Verify**: All 14 tables exist
3. **Check**: RLS policies are enabled
4. **Test**: Authentication settings

**🎯 Goal**: Complete database schema deployed and verified.

---

## **Phase 4: Storage & Authentication Setup** 🔐

### Step 4.1: Configure Storage Buckets
1. **Go to**: Storage in Supabase Dashboard
2. **Create Buckets**:
   - `user-files` (private, user-specific)
   - `app-defaults` (public, shared resources)
3. **Set Policies**: Verify bucket access policies

### Step 4.2: Configure Authentication
1. **Go to**: Authentication → Settings
2. **Enable Providers**:
   - Email/Password ✅
   - Google (if needed) ✅
   - Apple (if needed) ✅
3. **Set URLs**:
   - Site URL: Your app's URL
   - Redirect URLs: Add development URLs

### Step 4.3: Test Database Connection
```powershell
# Test connection
supabase db ping

# Check table access
supabase sql --query "SELECT count(*) FROM user_profiles;"
```

**🎯 Goal**: Full Supabase infrastructure operational and tested.

---

## **Phase 5: VSCode Integration & Workflow** 🛠️

### Step 5.1: Configure VSCode Settings
Create `.vscode/settings.json`:
```json
{
  "supabase.projectRef": "your-project-ref",
  "postgresql.connections": [{
    "name": "Supabase AAC DB",
    "host": "db.your-project-ref.supabase.co",
    "port": 5432,
    "database": "postgres",
    "username": "postgres",
    "password": "your-db-password",
    "ssl": true
  }]
}
```

### Step 5.2: Create Development Tasks
Add to `.vscode/tasks.json`:
```json
{
  "label": "Supabase: Start Local",
  "command": "supabase start"
},
{
  "label": "Supabase: Reset DB",
  "command": "supabase db reset"
}
```

### Step 5.3: Environment Configuration
Create environment files:
- `.env.local` (local development)
- `.env.production` (production deployment)

**🎯 Goal**: Seamless development workflow with VSCode integration.

---

## **Phase 6: Parallel Service Layer Creation** 🔄

### Step 6.1: Add Supabase Dependencies
```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
  connectivity_plus: ^5.0.0  # For network monitoring
```

### Step 6.2: Create Supabase Service (Parallel to Firebase)
- `lib/services/supabase_client.dart`
- `lib/services/supabase_auth_service.dart`
- `lib/services/supabase_data_service.dart`

### Step 6.3: Test Connectivity
Create simple test to verify Supabase connection works.

**🎯 Goal**: Working Supabase services alongside existing Firebase (no replacement yet).

---

## **Phase 7: Gradual Migration Phases** 🔄

### Phase 7a: Authentication Migration
- Replace Firebase Auth with Supabase Auth
- Update login/signup flows
- Maintain user sessions

### Phase 7b: Data Services Migration
- Replace DataServicesInitializer
- Update CRUD operations
- Implement sync service

### Phase 7c: Storage Migration
- Replace Firebase Storage with Supabase Storage
- Migrate file uploads
- Update image handling

### Phase 7d: Final Cleanup
- Remove Firebase dependencies
- Clean up unused code
- Performance optimization

**🎯 Goal**: Complete migration with zero downtime.

---

## **Commands Reference** 📋

### Daily Development Commands
```powershell
# Check Supabase status
supabase status

# Start local development
supabase start

# Reset database (careful!)
supabase db reset

# Generate types
supabase gen types dart --local > lib/types/supabase.dart

# Deploy changes
supabase db push

# View logs
supabase logs

# Stop local services
supabase stop
```

### Verification Commands
```powershell
# Test database connection
supabase db ping

# Check migration status
supabase migration list

# Verify auth settings
supabase auth list

# Check storage buckets
supabase storage ls
```

---

## **Risk Mitigation** ⚠️

### Backup Strategy
1. **Export current data** before starting migration
2. **Keep Firebase services running** during transition
3. **Test thoroughly** at each phase
4. **Have rollback plan** ready

### Testing Approach
1. **Unit tests** for new Supabase services
2. **Integration tests** for data flow
3. **Performance testing** for sync operations
4. **User acceptance testing** for UI flows

---

## **Success Criteria** ✅

### Phase Completion Checkpoints
- [ ] Supabase CLI working and accessible from PowerShell
- [ ] Online project created and accessible
- [ ] Database schema deployed successfully
- [ ] VSCode integration working
- [ ] Authentication configured
- [ ] Storage buckets operational
- [ ] Test connection successful
- [ ] Development workflow established

### Final Migration Success
- [ ] All Firebase functionality replicated in Supabase
- [ ] Zero data loss during migration
- [ ] Performance maintained or improved
- [ ] User experience unchanged
- [ ] Offline sync working perfectly

---

## **Next Action** 🚀

**Ready to start Phase 1?** Let's install Supabase CLI and get the development environment ready.

Would you like me to help you with the first command to install Supabase CLI?