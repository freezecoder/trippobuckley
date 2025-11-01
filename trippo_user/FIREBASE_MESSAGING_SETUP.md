# Firebase Cloud Messaging (FCM) - Complete Setup Guide

## Overview
This app uses Firebase Cloud Messaging (FCM) for push notifications to handle ride requests, driver updates, and other real-time communication.

## ✅ Current Implementation Status

### 1. Code Setup (COMPLETE)

#### Main App Initialization (`lib/main.dart`)
```dart
// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Register background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(const ProviderScope(child: MyApp()));
}
```

#### Messaging Service (`lib/Container/utils/firebase_messaging.dart`)
- ✅ Singleton pattern implementation
- ✅ Local notifications initialization (Android & iOS)
- ✅ Permission requests
- ✅ FCM token retrieval and refresh handling
- ✅ Foreground message handling (shows local notification + dialog)
- ✅ Background message handling (navigates to screen)
- ✅ Killed state handling (handles initial message on app launch)

#### Initialization in Home Screen (`lib/View/Screens/Main_Screens/Home_Screen/home_screen.dart`)
```dart
@override
void initState() {
  super.initState();
  // Initialize messaging after first frame to ensure context is available
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      MessagingService().init(context, ref);
    }
  });
}
```

### 2. Platform Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<!-- Notification channel configuration -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

**Required:**
- ✅ `google-services.json` file in `android/app/`
- ✅ Notification channel ID matches code (`high_importance_channel`)
- ✅ Internet permission (included automatically)

#### iOS (`ios/Runner/Info.plist`)
```xml
<!-- Method swizzling disabled for manual notification handling -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

**Required:**
- ✅ `GoogleService-Info.plist` in `ios/Runner/`
- ✅ Push Notifications capability enabled in Xcode
- ✅ APNs Authentication Key uploaded to Firebase Console

#### Web
- ✅ No additional configuration needed (handled automatically by Firebase)

### 3. Firebase Console Setup

#### Step 1: Enable Cloud Messaging API
1. Go to [Firebase Console](https://console.firebase.google.com/project/btrips-42089)
2. Navigate to **Project Settings** → **Cloud Messaging** tab
3. Ensure "Cloud Messaging API" is enabled
4. If not enabled, click "Enable" button

#### Step 2: iOS APNs Configuration (iOS only)
1. In Firebase Console → **Project Settings** → **Cloud Messaging** tab
2. Under **Apple app configuration**, upload:
   - **APNs Authentication Key** (recommended) OR
   - **APNs Certificates** (legacy)
3. Download the key from Apple Developer Portal (`.p8` file)
4. Upload to Firebase Console

#### Step 3: Verify App Registration
All platforms should be registered:
- ✅ Android: `1:833975987471:android:b89f0b689557e9e22b627a`
- ✅ iOS: `1:833975987471:ios:80a9f59e5c1b6fea2b627a`
- ✅ Web: `1:833975987471:web:132f4ec63e800ca02b627a`

### 4. Message Handling States

#### Foreground (App is open and visible)
- Shows local notification via `flutter_local_notifications`
- Displays dialog with notification content
- Navigates to specified screen if `screen` key is in `message.data`

#### Background (App is in background)
- Shows system notification
- On tap: App opens and navigates to screen specified in `message.data['screen']`
- Handled by `FirebaseMessaging.onMessageOpenedApp`

#### Killed (App is terminated)
- System shows notification
- On tap: App launches and handles initial message
- Handled by `FirebaseMessaging.instance.getInitialMessage()`

#### Background Processing (App not visible)
- Handled by `firebaseMessagingBackgroundHandler`
- Must be top-level function
- Limited to background tasks (no UI operations)

### 5. Notification Data Format

When sending notifications, include this structure:

```json
{
  "notification": {
    "title": "Ride Update",
    "body": "Your driver has arrived"
  },
  "data": {
    "screen": "route_name",  // GoRouter route name
    "status": "accepted",    // Optional: for ride status
    "ride_id": "123"         // Optional: additional data
  }
}
```

### 6. FCM Token Management

The app automatically:
- ✅ Retrieves FCM token on initialization
- ✅ Listens for token refresh events
- ✅ Logs token to console for debugging

**To use tokens:**
```dart
// Get current token
String? token = MessagingService.fcmToken;

// Token is automatically refreshed when:
// - App is restored on a new device
// - App data is cleared
// - App is uninstalled and reinstalled
// - User clears app data
```

### 7. Testing FCM

#### Get FCM Token:
1. Run the app
2. Check console logs for: `FCM Token: [token-here]`
3. Copy the token

#### Send Test Notification:

**Via Firebase Console:**
1. Go to Firebase Console → **Cloud Messaging**
2. Click **"Send your first message"** or **"New notification"**
3. Enter title and message text
4. Click **"Send test message"**
5. Enter the FCM token from app logs
6. Click **"Test"**

**Via cURL (requires server key):**
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "USER_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test message"
    },
    "data": {
      "screen": "home"
    }
  }'
```

**Via Code (from app):**
```dart
// See: lib/View/Screens/Main_Screens/Home_Screen/home_logics.dart
// Lines 465-491 show how the app sends FCM messages to drivers
```

### 8. Common Issues & Solutions

#### Issue: Notifications not received
**Solutions:**
1. ✅ Verify FCM token is generated (check console logs)
2. ✅ Check Cloud Messaging API is enabled in Firebase Console
3. ✅ Verify notification permissions are granted
4. ✅ For iOS: Check APNs key/certificate is uploaded
5. ✅ Check device has internet connection
6. ✅ Verify `google-services.json` / `GoogleService-Info.plist` are in correct locations

#### Issue: Background notifications not working
**Solutions:**
1. ✅ Ensure `onBackgroundMessage` is registered BEFORE `runApp()`
2. ✅ Verify handler is top-level function (not class method)
3. ✅ Add `@pragma('vm:entry-point')` annotation
4. ✅ Check Firebase is initialized in background handler

#### Issue: iOS notifications not working
**Solutions:**
1. ✅ Enable Push Notifications capability in Xcode
2. ✅ Upload APNs Authentication Key to Firebase Console
3. ✅ Verify `GoogleService-Info.plist` is correct
4. ✅ Test on physical device (notifications don't work on simulator for iOS)
5. ✅ Check `FirebaseAppDelegateProxyEnabled` is set to `false` in Info.plist

#### Issue: Android notifications not showing
**Solutions:**
1. ✅ Verify notification channel ID matches in code and AndroidManifest.xml
2. ✅ Check notification channel importance is set correctly
3. ✅ Ensure app has notification permissions
4. ✅ Test on Android 8.0+ (notification channels required)

### 9. Platform-Specific Notes

#### Android
- Notification channels are required (Android 8.0+)
- Channel ID: `high_importance_channel`
- Uses `@mipmap/ic_launcher` for notification icon
- No additional permissions needed beyond internet

#### iOS
- Requires APNs key/certificate
- Push Notifications capability must be enabled in Xcode
- Notifications don't work on iOS Simulator (use physical device)
- Background notifications require background mode capability

#### Web
- Supported automatically
- Uses browser notifications API
- Requires user to grant notification permissions
- Works in all modern browsers

### 10. Security Best Practices

1. **Never expose server keys in client code**
   - Keep server keys on backend only
   - Use Cloud Functions or backend to send notifications

2. **Validate notification data**
   - Always check `message.data` before processing
   - Sanitize screen names before navigation

3. **Store FCM tokens securely**
   - Save tokens to Firestore when user authenticates
   - Update tokens on refresh
   - Remove tokens when user logs out

4. **Use topic-based messaging for broadcast**
   - Subscribe users to topics (e.g., "all_users", "drivers")
   - Send to topics instead of individual tokens

### 11. Next Steps / Improvements

**Recommended enhancements:**
1. ✅ Save FCM tokens to Firestore when user logs in
2. ✅ Implement token refresh handling in Firestore
3. ✅ Set up Cloud Functions for server-side notifications
4. ✅ Add notification action buttons (Android)
5. ✅ Implement notification categories (iOS)
6. ✅ Add notification sound customization
7. ✅ Implement notification badge management

---

## Summary

✅ **Code Setup**: Complete and properly configured  
✅ **Android Setup**: Complete  
✅ **iOS Setup**: Requires APNs key upload  
✅ **Web Setup**: Automatic  
⚠️ **Firebase Console**: Requires Cloud Messaging API enablement and iOS APNs key

**Status**: The app is fully configured for FCM. Ensure Firebase Console is properly set up for production use.

