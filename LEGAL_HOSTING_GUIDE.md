# Legal Documents Hosting Instructions

## 📋 Overview

This guide explains how to host the legal documents required for Play Store submission. The documents have been prepared in HTML format for web accessibility.

## 📁 Generated Files

The following HTML files have been created in the `docs/` folder:

1. **`index.html`** - Main landing page with app information and links to legal documents
2. **`privacy-policy.html`** - Complete privacy policy with COPPA compliance
3. **`terms-of-service.html`** - Comprehensive terms of service

## 🚀 Hosting Options

### Option 1: GitHub Pages (Recommended)

**Prerequisites**: GitHub repository

**Steps**:
1. Commit the `docs/` folder to your GitHub repository
2. Go to your repository Settings
3. Navigate to "Pages" section
4. Set source to "Deploy from a branch"
5. Select `main` branch and `/docs` folder
6. Click "Save"

**Result**: Your documents will be available at:
- `https://[username].github.io/[repository-name]/`
- `https://[username].github.io/[repository-name]/privacy-policy.html`
- `https://[username].github.io/[repository-name]/terms-of-service.html`

### Option 2: Firebase Hosting

**Prerequisites**: Firebase project setup

**Steps**:
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`
3. Initialize hosting: `firebase init hosting`
4. Set public directory to `docs`
5. Deploy: `firebase deploy`

**Result**: Documents available at your Firebase hosting URL

### Option 3: Static Hosting Services

Upload the `docs/` folder to any static hosting service:
- **Netlify**: Drag and drop the docs folder
- **Vercel**: Connect GitHub repository
- **Surge.sh**: Use CLI to deploy
- **GitHub Pages**: Follow Option 1

## 📝 Required Updates

### 1. Update Contact Information

Replace placeholder contact information in both HTML files:
- `[Company Address]` → Your actual business address
- `[Phone Number]` → Your support phone number
- `privacy@aac-communication-helper.com` → Your actual email
- `support@aac-communication-helper.com` → Your actual email
- `coppa@aac-communication-helper.com` → Your actual email

### 2. Update App Configuration

After hosting, update your Flutter app to reference the hosted URLs:

**In `lib/screens/settings_screen.dart`** (or wherever you want to add legal links):

```dart
import 'package:url_launcher/url_launcher.dart';

class LegalSection extends StatelessWidget {
  // Replace with your actual hosted URLs
  final String privacyPolicyUrl = 'https://your-domain.com/privacy-policy.html';
  final String termsOfServiceUrl = 'https://your-domain.com/terms-of-service.html';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Privacy Policy'),
          subtitle: Text('Read our privacy policy'),
          leading: Icon(Icons.privacy_tip),
          onTap: () => _launchUrl(privacyPolicyUrl),
        ),
        ListTile(
          title: Text('Terms of Service'),
          subtitle: Text('Read our terms of service'),
          leading: Icon(Icons.description),
          onTap: () => _launchUrl(termsOfServiceUrl),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
```

**Add URL launcher dependency to `pubspec.yaml`**:
```yaml
dependencies:
  url_launcher: ^6.2.5
```

### 3. Play Store Console Configuration

When setting up your Play Store listing, provide these URLs:
- **Privacy Policy URL**: `https://your-domain.com/privacy-policy.html`
- **Terms of Service URL**: `https://your-domain.com/terms-of-service.html`

## 🔍 Verification Steps

### Test Your Hosted Documents

1. **Accessibility Test**: Ensure URLs are publicly accessible
2. **Mobile Test**: Verify documents display correctly on mobile devices
3. **Link Test**: Check that privacy policy and terms of service link to each other
4. **Content Test**: Verify all placeholder text has been replaced

### Play Store Requirements Checklist

- [ ] Privacy Policy URL is publicly accessible
- [ ] Terms of Service URL is publicly accessible  
- [ ] Documents load on mobile devices
- [ ] COPPA compliance information is present
- [ ] Contact information is accurate and current
- [ ] URLs are added to Play Store Console

## 📋 Final Play Store Submission Checklist

### Store Listing Assets ✅
- [x] App icon integrated in release build
- [x] Screenshots ready (5 screenshots in promotional folder)
- [x] Feature graphics ready (1024x500 for Play Store)
- [x] App description and metadata ready

### Legal Compliance ✅
- [x] Privacy policy created and ready to host
- [x] Terms of service created and ready to host
- [x] COPPA compliance statements included
- [x] Data safety information prepared

### Technical Requirements ✅
- [x] Release AAB built and signed (54.0MB)
- [x] Target SDK 34 (Play Store compliant)
- [x] Custom app icons integrated
- [x] Release keystore configured

### Next Steps Required

1. **Host Legal Documents** (Priority 1)
   - Choose hosting option (GitHub Pages recommended)
   - Update contact information in HTML files
   - Deploy and verify accessibility

2. **Update App** (Priority 2)
   - Add legal document links to settings screen
   - Add url_launcher dependency
   - Build final release with legal links

3. **Create Play Store Listing** (Priority 3)
   - Set up Google Play Console account
   - Upload AAB file
   - Add store assets and metadata
   - Configure legal document URLs

4. **Submit for Review** (Priority 4)
   - Complete data safety questionnaire
   - Set pricing and distribution
   - Submit for Google Play review

## 🎯 Estimated Timeline

- **Legal hosting**: 1-2 hours
- **App updates**: 2-3 hours  
- **Play Store setup**: 3-4 hours
- **Review process**: 3-7 days (Google's timeline)

**Total time to submission**: 1-2 days of work + Google's review time

## 📞 Support

If you encounter issues during deployment:
1. Check that all placeholder text has been replaced
2. Verify URLs are publicly accessible
3. Test on different devices and browsers
4. Ensure Play Store Console can access the URLs

---

**Status**: Ready for legal document hosting and final Play Store submission preparation! 🚀
