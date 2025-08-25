# Web-Accessible Legal Documents

This document explains how to make the privacy policy and terms of service accessible via the web for app store compliance.

## Web Hosting Options

### Option 1: GitHub Pages (Recommended for Open Source Projects)

1. Create a `docs` folder in your repository
2. Copy the markdown files to the docs folder:
   ```bash
   mkdir docs
   cp PRIVACY_POLICY.md docs/privacy-policy.md
   cp TERMS_OF_SERVICE.md docs/terms-of-service.md
   ```

3. Convert markdown to HTML or use GitHub's automatic rendering
4. Enable GitHub Pages in repository settings
5. Set source to "Deploy from a branch" and select `/docs` folder

### Option 2: Firebase Hosting

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Initialize Firebase in your project:
   ```bash
   firebase login
   firebase init hosting
   ```

3. Create a public directory with HTML versions:
   ```bash
   mkdir public
   # Convert markdown to HTML or create simple HTML files
   ```

4. Deploy:
   ```bash
   firebase deploy
   ```

### Option 3: Simple Static Hosting

Create simple HTML versions of your documents:

#### privacy-policy.html
```html
<!DOCTYPE html>
<html>
<head>
    <title>Privacy Policy - AAC Communication Helper</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <h1>Privacy Policy for AAC Communication Helper</h1>
    
    <p><strong>Last Updated:</strong> August 24, 2025</p>
    
    <h2>Introduction</h2>
    <p>AAC Communication Helper ("we," "our," or "us") is committed to protecting the privacy of all users, especially children under the age of 13. This Privacy Policy explains how we collect, use, disclose, and safeguard your information in compliance with the Children's Online Privacy Protection Act ("COPPA") and other applicable privacy laws.</p>
    
    <!-- Include the full content of your PRIVACY_POLICY.md here -->
    <!-- Convert markdown formatting to HTML -->
    
    <h2>Contact Us</h2>
    <p>If you have any questions about this Privacy Policy or our privacy practices, please contact us at:</p>
    <p><strong>Email:</strong> privacy@aac-communication-helper.com</p>
    
    <h2>How to Contact Us About COPPA Rights</h2>
    <p>Parents who believe we may have collected personal information from their child without consent, or who wish to exercise their COPPA rights, can contact us at:</p>
    <p><strong>Email:</strong> coppa@aac-communication-helper.com</p>
</body>
</html>
```

#### terms-of-service.html
```html
<!DOCTYPE html>
<html>
<head>
    <title>Terms of Service - AAC Communication Helper</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <h1>Terms of Service for AAC Communication Helper</h1>
    
    <p><strong>Last Updated:</strong> August 24, 2025</p>
    
    <h2>Introduction</h2>
    <p>Welcome to AAC Communication Helper ("App," "we," "us," or "our"). These Terms of Service ("Terms") govern your access to and use of our mobile application designed to assist individuals with communication challenges through Augmentative and Alternative Communication (AAC) tools.</p>
    
    <!-- Include the full content of your TERMS_OF_SERVICE.md here -->
    <!-- Convert markdown formatting to HTML -->
    
    <h2>Contact Information</h2>
    <p>If you have any questions about these Terms, please contact us at:</p>
    <p><strong>Email:</strong> support@aac-communication-helper.com</p>
</body>
</html>
```

## In-App Disclosure Implementation

Add links to legal documents in your app:

### In Flutter Code (lib/screens/settings_screen.dart)
```dart
import 'package:url_launcher/url_launcher.dart';

class LegalDocumentsSection extends StatelessWidget {
  final String privacyPolicyUrl = 'https://your-domain.com/privacy-policy.html';
  final String termsOfServiceUrl = 'https://your-domain.com/terms-of-service.html';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('Privacy Policy'),
          subtitle: Text('Read our privacy policy'),
          onTap: () => _launchUrl(privacyPolicyUrl),
        ),
        ListTile(
          title: Text('Terms of Service'),
          subtitle: Text('Read our terms of service'),
          onTap: () => _launchUrl(termsOfServiceUrl),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
```

### Add URL Launcher Dependency
In `pubspec.yaml`:
```yaml
dependencies:
  url_launcher: ^6.2.5
```

## App Store Compliance

### Google Play Store Requirements

1. **Privacy Policy URL**: Must be accessible via HTTP/HTTPS
2. **Content**: Must clearly describe data collection and usage
3. **COPPA Compliance**: Must have specific provisions for children's data
4. **Accessibility**: Must be easily accessible from within the app

### Apple App Store Requirements

1. **Privacy Policy URL**: Must be provided during app submission
2. **Privacy Labels**: Complete privacy labels in App Store Connect
3. **Data Collection**: Clearly disclose all data collection practices
4. **Children's Apps**: Additional requirements for apps targeting children

## Testing Web Accessibility

Before submitting to app stores, verify that your documents are accessible:

1. Open the URLs in different browsers
2. Check on mobile devices
3. Verify all links work correctly
4. Ensure proper formatting and readability
5. Test with screen readers for accessibility

## Updates and Maintenance

1. **Version Control**: Keep legal documents in version control
2. **Update Tracking**: Track when documents were last updated
3. **Change Notification**: Consider notifying users of significant changes
4. **Regular Review**: Review documents annually or when laws change

## Additional Considerations

### Multiple Language Support
Consider providing translated versions of legal documents for international markets.

### Cookie Policy
If your app or website uses cookies, create a separate cookie policy document.

### Third-Party Services Disclosure
If you use third-party services (analytics, crash reporting, etc.), disclose this in your privacy policy.

### Data Deletion Requests
Provide clear instructions for users to request deletion of their data.

## Example Implementation in App

### Settings Screen Legal Section
```
Legal & Privacy
├── Privacy Policy
├── Terms of Service
├── Data Collection Disclosure
└── Request Data Deletion
```

### Data Collection Disclosure Example
Create a simple screen that explains what data is collected:

```dart
class DataCollectionDisclosure extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data Collection')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data We Collect', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 16),
            Text('• User profiles and preferences'),
            Text('• Communication symbols and categories'),
            Text('• Usage statistics (anonymous)'),
            Text('• Crash reports (anonymous)'),
            // Add more as needed
          ],
        ),
      ),
    );
  }
}
```

This approach ensures compliance with app store requirements while providing users with clear access to legal information.