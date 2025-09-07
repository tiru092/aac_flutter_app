# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**Svarah** is an Augmentative and Alternative Communication (AAC) Flutter app designed to assist individuals with communication challenges. The app provides communication symbols, voice recording, text-to-speech, learning goals, and accessibility features. It's built with Firebase backend integration for authentication, data sync, and cloud storage.

## Essential Development Commands

### Setup and Dependencies
```powershell
# Initial setup
flutter pub get
flutter pub run build_runner build  # Generate Hive adapters

# Clean and rebuild (for resolving dependency issues)
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Development
```powershell
# Run in debug mode
flutter run

# Run specific entry points for testing
flutter run lib/main_minimal.dart      # Minimal version for testing
flutter run lib/main_simple.dart       # Simple version without complex features
flutter run lib/main_recording_test.dart # For testing voice recording

# Hot reload and hot restart are available during development
# r = hot reload, R = hot restart, q = quit
```

### Testing
```powershell
# Run all tests
flutter test

# Run specific test files
flutter test test/auth_service_test.dart
flutter test test/encryption_service_test.dart

# Run tests with coverage
flutter test --coverage
```

### Analysis and Quality
```powershell
# Run Dart analyzer
flutter analyze

# Check for formatting issues
dart format --set-exit-if-changed .

# Fix formatting
dart format .
```

### Building
```powershell
# Debug builds
flutter build apk --debug
flutter build appbundle --debug

# Release builds (requires keystore setup)
flutter build apk --release
flutter build appbundle --release

# Web build (limited functionality due to native dependencies)
flutter build web
```

### Firebase and Hive Code Generation
```powershell
# Generate Hive type adapters (required after model changes)
flutter pub run build_runner build

# Force regeneration of adapters
flutter pub run build_runner build --delete-conflicting-outputs
```

## Architecture Overview

### Core Architecture Pattern
The app follows a **service-based architecture** with clear separation of concerns:

- **Models** (`lib/models/`): Data structures with Hive serialization for local storage
- **Services** (`lib/services/`): Business logic and external integrations
- **Screens** (`lib/screens/`): UI components organized by feature
- **Widgets** (`lib/widgets/`): Reusable UI components

### Key Architectural Components

#### Authentication Flow
- **AuthWrapper** (`lib/widgets/auth_wrapper.dart`): Manages authentication state routing
- **AuthService** (`lib/services/auth_service.dart`): Firebase authentication with comprehensive error handling
- **AuthWrapperService** (`lib/services/auth_wrapper_service.dart`): Authentication state management

#### Data Architecture
- **Offline-First Design**: Uses Hive for local storage with Firebase sync
- **MigrationService** (`lib/services/migration_service.dart`): Handles data migrations between app versions
- **DataRecoveryService** (`lib/services/data_recovery_service.dart`): Recovers corrupted local data
- **EncryptionService** (`lib/services/encryption_service.dart`): AES-256 encryption for sensitive data
- **CloudSyncService**: Syncs local Hive data with Firebase Firestore

#### Core Services
- **VoiceService**: Custom voice recording and Text-to-Speech integration
- **UserProfileService**: Multi-profile support with encrypted storage
- **AACHelper** (`lib/utils/aac_helper.dart`): Core AAC functionality and symbol management
- **BackupService**: Automated backup and restore functionality
- **GooglePlayBillingService**: In-app purchase management for subscriptions

### Data Flow
1. **Local-First**: All data operations begin with Hive (local storage)
2. **Background Sync**: CloudSyncService syncs changes to Firebase when connected
3. **Conflict Resolution**: Last-write-wins with timestamp comparison
4. **Offline Support**: Full app functionality without internet connection

### Entry Points
- `lib/main.dart`: Production entry point with Firebase initialization
- `lib/main_minimal.dart`: Minimal version for testing core features
- `lib/main_simple.dart`: Simplified version without complex authentication
- `lib/main_recording_test.dart`: Specific for testing voice recording functionality

### Firebase Integration
- **Authentication**: Email/password with email verification
- **Firestore**: User profiles, communication history, learning goals
- **Storage**: Voice recordings and custom symbols
- **Crashlytics**: Error tracking and performance monitoring
- **Analytics**: User behavior tracking (with consent)

### Model Structure
Key models with Hive serialization:
- **Symbol** (`lib/models/symbol.dart`): Communication symbols with categories
- **UserProfile** (`lib/models/user_profile.dart`): User configuration and preferences
- **CommunicationHistory** (`lib/models/communication_history.dart`): Usage tracking
- **Goal** and variants: Learning goal system models

## Important Development Notes

### Firebase Setup Requirements
- **google-services.json** must be placed in `android/app/` for Firebase integration
- Firebase services initialization handled in main.dart with error recovery
- Offline-first architecture ensures app works without Firebase

### Code Generation
- Run `flutter pub run build_runner build` after modifying any model class with Hive annotations
- Required for proper serialization of data models

### Testing Strategy
- Unit tests for core services (auth, encryption, cloud sync)
- Widget tests for reusable components  
- Integration tests for critical user flows
- Comprehensive error handling tests

### Platform Considerations
- **Android**: Primary platform with full feature support
- **iOS**: Basic support (not fully configured)
- **Web**: Limited functionality due to native plugin dependencies

### Security Implementation
- AES-256 encryption for sensitive data using EncryptionService
- Secure storage via flutter_secure_storage for encryption keys
- Firebase security rules for data access control
- COPPA compliance features built-in

### Performance Optimization
- Lazy loading of symbols and images
- Cached network images for better performance
- Optimized Firebase queries with indexed fields
- Memory-efficient voice recording with compression

### Development Environment
- **Flutter SDK**: 3.32.8 (stable channel)
- **Dart SDK**: >=3.0.0 <4.0.0
- **Target Android API**: 34+
- **Minimum Android API**: 21 (Android 5.0)

## Common Development Workflows

### Adding New Features
1. Create model classes with Hive annotations if data persistence needed
2. Run `flutter pub run build_runner build` to generate adapters
3. Implement service layer for business logic
4. Create UI components in screens/widgets
5. Add unit tests for service layer
6. Update this WARP.md if architecture changes

### Debugging Firebase Issues
1. Check Firebase initialization in main.dart
2. Verify google-services.json is present and valid
3. Use `flutter run --verbose` for detailed Firebase logs
4. Test offline functionality to isolate network issues

### Voice Recording Development
- Use `lib/main_recording_test.dart` for focused voice feature testing
- Test on physical devices (emulator audio recording is unreliable)
- VoiceService handles permissions and audio quality automatically

### Profile and Authentication Testing
- Multiple main entry points allow testing different authentication states
- AuthWrapper handles all authentication routing logic
- Profile system supports multiple user profiles per device
