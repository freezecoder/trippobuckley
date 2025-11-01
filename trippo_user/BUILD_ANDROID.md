# Android APK Build Guide

This guide explains how to build an Android APK for the BTrips/Trippo User app.

## Quick Start

### Using the Build Script (Recommended)

Simply run the build script:

```bash
./build-android-apk.sh
```

The script will:
1. ✅ Clean previous builds
2. ✅ Get dependencies
3. ✅ Build release APK
4. ✅ Show APK location and installation instructions

### Manual Build

If you prefer to build manually:

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build release APK
flutter build apk --release
```

## Build Output

**APK Location:**
```
build/app/outputs/flutter-apk/app-release.apk
```

**Package Name:** `dev.hyderali.trippo_user`

**File Size:** ~57-60 MB

## Installation Methods

### Method 1: ADB (Recommended for Development)

```bash
# Connect device via USB and enable USB debugging
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Manual Transfer

1. Copy `app-release.apk` to your Android device
2. On your device, go to **Settings → Security**
3. Enable **Install from Unknown Sources**
4. Open the APK file using a File Manager
5. Tap **Install**

### Method 3: Cloud Transfer

1. Upload APK to Google Drive, Dropbox, or similar
2. Download on your Android device
3. Install from Downloads folder

## Build Configuration

The app is configured with the following build tools:

- **Gradle:** 8.10
- **Android Gradle Plugin (AGP):** 8.7.1
- **Kotlin:** 2.1.0
- **Build Tools:** 33.0.1
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 33 (Android 13)

## Firebase Integration

The APK is pre-configured with Firebase:

- **Project ID:** trippo-42089
- **Package Name:** dev.hyderali.trippo_user
- **Firebase Services:**
  - Authentication
  - Cloud Firestore
  - Firebase Messaging
  - Firebase Storage

## Signing Configuration

⚠️ **Important:** This build uses **debug signing** for development/testing.

For **production release** to Google Play Store:

1. Generate a keystore:
```bash
keytool -genkey -v -keystore ~/trippo-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias trippo-key
```

2. Update `android/app/build.gradle` with release signing config:
```gradle
signingConfigs {
    release {
        storeFile file('/path/to/trippo-release-key.jks')
        storePassword 'your-password'
        keyAlias 'trippo-key'
        keyPassword 'your-password'
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

3. Build signed release:
```bash
flutter build apk --release
```

## Build Splits (Optional)

To reduce APK size, you can build separate APKs for different CPU architectures:

```bash
flutter build apk --split-per-abi
```

This creates:
- `app-armeabi-v7a-release.apk` (~20MB) - 32-bit ARM
- `app-arm64-v8a-release.apk` (~22MB) - 64-bit ARM
- `app-x86_64-release.apk` (~23MB) - 64-bit x86

## Troubleshooting

### Build Fails with Gradle Error

```bash
# Try cleaning and rebuilding
flutter clean
rm -rf android/.gradle
flutter pub get
flutter build apk --release
```

### Firebase Connection Issues

Ensure `google-services.json` is in `android/app/` directory.

### Package Name Mismatch

The package name must match Firebase configuration:
- **Build Gradle:** `dev.hyderali.trippo_user`
- **Firebase Console:** `dev.hyderali.trippo_user`

### Out of Memory Error

Increase Gradle memory in `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx2048M
```

## Platform Compatibility

✅ **Android:** Full support (this APK)  
✅ **Web:** Use `flutter run -d chrome` for web development  
❌ **iOS:** Requires Xcode and macOS for building

## Next Steps

After building the APK:

1. **Test on Physical Device:** Install and test all features
2. **Test Firebase Integration:** Verify auth, database, storage
3. **Test Permissions:** Location, notifications, storage
4. **Performance Testing:** Check app performance and battery usage
5. **Prepare for Release:** Configure release signing and ProGuard

## Support

For issues or questions:
- Check Flutter logs: `flutter logs`
- Check Android logs: `adb logcat`
- Review Firebase Console for backend issues

## Version History

- **Current Build:** Release with Android Gradle Plugin 8.7.1
- **Package:** dev.hyderali.trippo_user
- **Firebase Project:** trippo-42089

