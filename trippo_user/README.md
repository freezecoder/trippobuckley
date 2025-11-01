# BTrips User - Developer Documentation

A Flutter-based ride-hailing application for users, built with Firebase backend services. This is the user-facing mobile application that enables users to book rides, track drivers in real-time, and manage their ride history.

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Architecture](#project-architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Configuration](#configuration)
- [Development Workflow](#development-workflow)
- [Key Components](#key-components)
- [State Management](#state-management)
- [API Integration](#api-integration)
- [Building & Deployment](#building--deployment)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

**BTrips User** is the passenger-facing application of the BTrips ride-hailing platform. It provides users with the ability to:

- Authenticate using Firebase Authentication
- Search and select pickup/dropoff locations using Google Places API
- View real-time driver locations on Google Maps
- Book rides and track them in real-time
- Receive push notifications for ride updates
- View ride history and manage profile

The application follows a clean architecture pattern with clear separation of concerns:
- **View Layer**: UI screens and components
- **Container Layer**: Business logic, repositories, and utilities
- **Model Layer**: Data models and structures

## Tech Stack

### Core Framework
- **Flutter SDK**: `>=3.0.6 <4.0.0`
- **Dart**: Modern Dart with null safety

### State Management
- **flutter_riverpod**: `^2.3.6` - Reactive state management

### Navigation
- **go_router**: `^9.1.0` - Declarative routing solution

### Firebase Services
- **firebase_core**: `^2.15.0` - Firebase initialization
- **firebase_auth**: `^4.7.1` - User authentication
- **cloud_firestore**: `^4.8.3` - NoSQL database
- **firebase_messaging**: `^14.6.7` - Push notifications
- **flutter_local_notifications**: `^15.1.1` - Local notification display

### Maps & Location
- **google_maps_flutter**: `^2.8.0` - Google Maps integration
- **geolocator**: `^10.0.0` - Location services
- **geocoder2**: `^1.4.0` - Reverse geocoding
- **flutter_polyline_points**: `^1.0.0` - Route polylines
- **geoflutterfire2**: `^2.3.15` - Geospatial queries

### Networking & HTTP
- **dio**: `^5.3.2` - HTTP client for API calls

### UI & Animation
- **lottie**: `^2.6.0` - Lottie animations
- **elegant_notification**: `^1.10.1` - Toast notifications

### Development Tools
- **flutter_lints**: `^2.0.0` - Linting rules
- **custom_lint**: `^0.5.2` - Custom linting
- **riverpod_lint**: `^2.0.1` - Riverpod-specific lints

## Project Architecture

```
btrips_user/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase platform configs
│   │
│   ├── Container/                   # Business Logic Layer
│   │   ├── Repositories/           # Data access layer
│   │   │   ├── auth_repo.dart
│   │   │   ├── firestore_repo.dart
│   │   │   ├── address_parser_repo.dart
│   │   │   ├── direction_polylines_repo.dart
│   │   │   ├── place_details_repo.dart
│   │   │   └── predicted_places_repo.dart
│   │   └── utils/                   # Utility classes
│   │       ├── keys.dart            # API keys (gitignored)
│   │       ├── error_notification.dart
│   │       ├── firebase_messaging.dart
│   │       └── set_blackmap.dart
│   │
│   ├── Model/                       # Data Models
│   │   ├── direction_model.dart
│   │   ├── direction_polyline_details_model.dart
│   │   ├── driver_model.dart
│   │   └── predicted_places.dart
│   │
│   └── View/                        # Presentation Layer
│       ├── Components/              # Reusable widgets
│       ├── Routes/                  # Navigation configuration
│       │   ├── app_routes.dart
│       │   └── routes.dart
│       ├── Screens/                 # UI Screens
│       │   ├── Auth_Screens/
│       │   ├── Main_Screens/
│       │   └── Other_Screens/
│       └── Themes/                  # App theming
│           └── app_theme.dart
│
├── assets/
│   ├── fonts/                       # Custom fonts
│   ├── imgs/                        # Images
│   └── jsons/                       # JSON assets
│
├── android/                         # Android-specific config
├── ios/                             # iOS-specific config
├── web/                             # Web platform support
├── macos/                           # macOS platform support
├── windows/                         # Windows platform support
├── linux/                           # Linux platform support
│
├── pubspec.yaml                     # Dependencies & config
└── firebase.json                    # Firebase config
```

## Project Structure

### Container Layer (Business Logic)

#### Repositories
Each repository handles data operations for a specific domain:

- **auth_repo.dart**: Firebase Authentication operations (login, register)
- **firestore_repo.dart**: Firestore database operations
- **address_parser_repo.dart**: Address parsing and formatting
- **direction_polylines_repo.dart**: Google Maps Directions API integration
- **place_details_repo.dart**: Google Places API for location details
- **predicted_places_repo.dart**: Google Places Autocomplete predictions

#### Utilities
- **keys.dart**: API keys and configuration (⚠️ **Git-ignored - must be created manually**)
- **error_notification.dart**: Error handling and user notifications
- **firebase_messaging.dart**: Push notification initialization and handling
- **set_blackmap.dart**: Custom Google Maps styling

### View Layer

#### Routes
- **app_routes.dart**: GoRouter configuration with all route definitions
- **routes.dart**: Route name constants

#### Screens
Organized by feature area:
- **Auth_Screens**: Login and registration
- **Main_Screens**: Home screen and ride booking flows
- **Other_Screens**: Splash screen, error screens, etc.

Each screen typically follows this structure:
```
ScreenName/
├── screen_name.dart          # UI Widget
├── screen_name_logics.dart   # Business logic
└── screen_name_providers.dart # Riverpod providers
```

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (>=3.0.6): [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK**: Included with Flutter
- **Android Studio** / **VS Code** with Flutter extensions
- **Xcode** (for iOS development on macOS)
- **CocoaPods** (for iOS): `sudo gem install cocoapods`
- **Firebase CLI**: `npm install -g firebase-tools`

### Required Accounts & Services

1. **Google Cloud Platform Account**
   - For Google Maps API
   - For Google Places API

2. **Firebase Project**
   - Firebase Authentication
   - Cloud Firestore
   - Firebase Cloud Messaging
   - Firebase Storage (optional)

3. **Stripe Account** (optional, for payments)
   - Publishable Key
   - Secret Key

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd btrips_user
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing project `btrips-42089`
3. Enable the following services:
   - Authentication (Email/Password)
   - Cloud Firestore Database
   - Firebase Cloud Messaging
   - Cloud Storage (if needed)

#### Configure Android
1. In Firebase Console, add an Android app with package name from `android/app/build.gradle`
2. Download `google-services.json`
3. Place it in `android/app/google-services.json`
4. Ensure `android/build.gradle` includes the Google Services plugin

#### Configure iOS
1. In Firebase Console, add an iOS app with bundle ID from `ios/Runner/Info.plist`
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/GoogleService-Info.plist`
4. Add to Xcode project (if not automatically added)

#### Configure macOS
1. Download `GoogleService-Info.plist` for macOS
2. Place it in `macos/Runner/GoogleService-Info.plist`
3. Add to Xcode project

### 4. Google Maps & Places API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project or select existing
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Directions API
   - Geocoding API
4. Create API keys for each platform (Android, iOS, Web)
5. Restrict API keys to specific services and platforms

### 5. Configure API Keys

**⚠️ Important**: The `lib/Container/utils/keys.dart` file is gitignored for security.

Create the file manually:

```dart
class Keys {
  // Google Maps API Key
  static const String mapKey = "YOUR_GOOGLE_MAPS_API_KEY";
  
  // Stripe Keys (if needed for payments)
  static const String stripePublishableKey = "YOUR_STRIPE_PUBLISHABLE_KEY";
  static const String stripeSecretKey = "YOUR_STRIPE_SECRET_KEY";
  
  // Firebase Configuration (if needed)
  static const String firebaseApiKey = "YOUR_FIREBASE_API_KEY";
  static const String firebaseProjectId = "btrips-42089";
}
```

### 6. Platform-Specific Setup

#### Android
1. Update `android/app/build.gradle`:
   ```gradle
   defaultConfig {
       minSdkVersion 21
       // ... other config
   }
   ```

2. Add permissions in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   ```

#### iOS
1. Update `ios/Podfile` if needed
2. Run `cd ios && pod install`
3. Add location permissions to `ios/Runner/Info.plist`:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location to provide ride services</string>
   <key>NSLocationAlwaysUsageDescription</key>
   <string>We need your location to track your ride</string>
   ```

#### macOS
1. Run `cd macos && pod install`
2. Add location permissions to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`

### 7. Verify Setup

Run the app to verify everything is configured correctly:

```bash
# Check for available devices
flutter devices

# Run on a device/emulator
flutter run

# Or specify a device
flutter run -d <device-id>
```

## Configuration

### Environment-Specific Configuration

The app uses platform-specific Firebase configuration from `firebase_options.dart`, which is auto-generated. To regenerate:

```bash
flutterfire configure
```

### Custom Fonts

The app uses custom fonts defined in `pubspec.yaml`:
- `Bold.ttf`
- `Light.ttf`
- `Medium.ttf`
- `Regular.ttf`
- `SemiBold.ttf`

These are referenced in the theme as `fontFamily: "regular"`, `"medium"`, etc.

### App Theme

Theme configuration is in `lib/View/Themes/app_theme.dart`:
- Dark theme (black background)
- Custom text styles with custom fonts
- Material 3 enabled

## Development Workflow

### Running the App

```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Run with specific flavor (if configured)
flutter run --flavor development
```

### Hot Reload & Hot Restart

- **Hot Reload**: Press `r` in the terminal (preserves state)
- **Hot Restart**: Press `R` in the terminal (resets state)
- **Quit**: Press `q` in the terminal

### Code Generation

If using code generation (riverpod_generator, freezed, etc.):

```bash
flutter pub run build_runner build
flutter pub run build_runner watch
```

### Linting

```bash
# Analyze code
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## Key Components

### State Management with Riverpod

The app uses Riverpod for state management. Providers are defined in screen-specific `*_providers.dart` files.

**Example Provider Structure:**
```dart
final homeScreenPickUpLocationProvider = StateProvider<Direction?>((ref) {
  return null;
});
```

**Usage in Widgets:**
```dart
ref.watch(providerName)        // Read value
ref.read(providerName.notifier) // Access notifier
```

### Navigation with GoRouter

Routes are defined in `lib/View/Routes/app_routes.dart`:

```dart
context.goNamed(Routes().home);           // Navigate
context.pushNamed(Routes().whereTo);      // Push route
context.pop();                            // Go back
```

### Repository Pattern

Repositories abstract data operations:

```dart
final globalAuthRepoProvider = Provider<AuthRepo>((ref) {
  return AuthRepo();
});

// Usage
ref.read(globalAuthRepoProvider).loginUser(email, password, context);
```

### Google Maps Integration

The app uses Google Maps Flutter plugin with custom styling:

```dart
GoogleMap(
  onMapCreated: (controller) {
    SetBlackMap().setBlackMapTheme(controller);
  },
  markers: ref.watch(homeScreenMainMarkersProvider),
  polylines: ref.watch(homeScreenMainPolylinesProvider),
)
```

## State Management

### Provider Types Used

1. **StateProvider**: Simple state management
   ```dart
   final homeScreenRateProvider = StateProvider<double?>((ref) => null);
   ```

2. **Provider**: Singleton services/repositories
   ```dart
   final globalAuthRepoProvider = Provider<AuthRepo>((ref) => AuthRepo());
   ```

### Provider Organization

Providers are organized by screen/feature:
- `home_providers.dart` - Home screen state
- `login_providers.dart` - Login screen state
- etc.

### Best Practices

- Keep providers close to where they're used
- Use `ref.watch()` for reactive updates
- Use `ref.read()` for one-time access (e.g., in callbacks)

## API Integration

### Google Maps/Places APIs

APIs are called via repositories using `dio`:

- **Places Autocomplete**: `PredictedPlacesRepo`
- **Place Details**: `PlaceDetailsRepo`
- **Directions**: `DirectionPolylinesRepo`
- **Geocoding**: `AddressParserRepo`

### Firebase Services

- **Authentication**: `AuthRepo` uses `FirebaseAuth`
- **Database**: `FirestoreRepo` uses `CloudFirestore`
- **Messaging**: `MessagingService` handles FCM notifications

### Error Handling

Errors are displayed using `ErrorNotification`:

```dart
ErrorNotification().showError(context, "Error message");
```

## Building & Deployment

### Android

#### Debug Build
```bash
flutter build apk --debug
flutter build appbundle --debug
```

#### Release Build
```bash
# Generate signing key (one-time)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configure signing in android/app/build.gradle
flutter build apk --release
flutter build appbundle --release
```

### iOS

#### Debug Build
```bash
flutter build ios --debug
```

#### Release Build
```bash
flutter build ios --release

# Then archive and upload via Xcode
open ios/Runner.xcworkspace
```

### macOS

```bash
flutter build macos --release
```

### Web

```bash
flutter build web --release
```

## Troubleshooting

### Common Issues

#### 1. Google Maps Not Showing
- Verify API key in `keys.dart`
- Check API restrictions in Google Cloud Console
- Ensure Maps SDK is enabled for your platform

#### 2. Firebase Initialization Errors
- Verify `google-services.json` / `GoogleService-Info.plist` are in correct locations
- Check `firebase_options.dart` is up to date
- Run `flutterfire configure` to regenerate

#### 3. Location Permissions
- Ensure permissions are added to platform-specific manifest/plist files
- Request permissions at runtime using `geolocator`

#### 4. Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### 5. iOS Pod Issues
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

#### 6. Android Gradle Issues
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Debug Mode

Enable verbose logging:
```bash
flutter run --verbose
```

## Contributing

### Development Guidelines

1. **Code Style**: Follow Dart/Flutter style guidelines
2. **Linting**: Run `flutter analyze` before committing
3. **State Management**: Use Riverpod providers, avoid setState where possible
4. **Architecture**: Keep business logic in repositories, UI in screens
5. **Error Handling**: Always wrap async operations in try-catch
6. **Documentation**: Document complex logic with comments

### Git Workflow

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes and test thoroughly
3. Run linter: `flutter analyze`
4. Commit with clear messages
5. Push and create a pull request

### Code Review Checklist

- [ ] Code follows project structure
- [ ] No linting errors
- [ ] Error handling implemented
- [ ] State managed with Riverpod
- [ ] Navigation uses GoRouter
- [ ] Firebase operations are wrapped in try-catch
- [ ] Location permissions handled properly

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Firebase Flutter Documentation](https://firebase.flutter.dev)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)

---

**Note**: This README is maintained by the development team. For questions or issues, please refer to the project's issue tracker or contact the maintainers.
