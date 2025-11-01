# Firebase Cloud Messaging (FCM) Configuration

## Setup Completed ✅

### 1. Firebase CLI Configuration
- Project: `btrips-42089`
- Firebase project is active and linked
- Firestore rules deployed

### 2. App Registration
All platforms are registered in Firebase:
- ✅ Android: `1:833975987471:android:b89f0b689557e9e22b627a`
- ✅ iOS: `1:833975987471:ios:80a9f59e5c1b6fea2b627a`
- ✅ Web: `1:833975987471:web:132f4ec63e800ca02b627a`
- ✅ Windows (Web): `1:833975987471:web:0e207931c63e24472b627a`

### 3. Code Configuration (Already Done)
- ✅ Background message handler configured in `main.dart`
- ✅ Local notifications plugin initialized
- ✅ FCM token retrieval and refresh handling
- ✅ Foreground, background, and killed state notification handling
- ✅ iOS and Android notification channels configured

### 4. Required Firebase Console Actions

#### Enable Cloud Messaging API (if not already enabled):
1. Go to [Firebase Console](https://console.firebase.google.com/project/btrips-42089)
2. Navigate to **Project Settings** → **Cloud Messaging**
3. Ensure Cloud Messaging API is enabled
4. For iOS: Upload your APNs Authentication Key (if not already done)

#### Verify Services:
```bash
# Check if FCM API is enabled (requires gcloud CLI)
gcloud services list --enabled --project=btrips-42089 --filter="name:fcm.googleapis.com"
```

### 5. Testing FCM

#### Get FCM Token:
When the app runs, check the console logs for:
```
FCM Token: [your-token-here]
```

#### Send Test Notification via Firebase Console:
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and message
4. Select target: Test on a device
5. Enter the FCM token from app logs
6. Send test message

#### Send via Firebase CLI:
```bash
# Note: This requires a server token from Firebase Console
firebase messaging:send \
  --token="YOUR_FCM_TOKEN" \
  --title="Test Notification" \
  --body="This is a test message"
```

### 6. Current Implementation Status

✅ **Background Handler**: Configured in `main.dart`  
✅ **Local Notifications**: Initialized for Android and iOS  
✅ **Token Management**: Automatic retrieval and refresh  
✅ **Foreground Handling**: Shows local notification + dialog  
✅ **Background Handling**: Navigates to specified screen  
✅ **Killed State**: Handles initial message on launch  
✅ **Permission Requests**: Configured for both platforms  

### 7. Platform-Specific Notes

#### Android:
- Notification channel: `high_importance_channel`
- Configured in `AndroidManifest.xml`
- No additional setup needed

#### iOS:
- Requires APNs certificate/key in Firebase Console
- Configured in `Info.plist`
- Push notifications capability must be enabled in Xcode

### 8. Next Steps (Optional)

1. **Save FCM Tokens to Firestore**:
   - Store user tokens in Firestore when user logs in
   - Update tokens on refresh
   - Use tokens for targeted messaging

2. **Cloud Functions** (Optional):
   - Set up Cloud Functions to send notifications server-side
   - Handle ride status updates
   - Send notifications when driver accepts/declines rides

### 9. Troubleshooting

If notifications aren't working:
1. Verify FCM token is being generated (check console logs)
2. Ensure Cloud Messaging API is enabled in Firebase Console
3. Check notification permissions are granted
4. For iOS: Verify APNs key/certificate is uploaded
5. Check device/emulator has internet connection

### Commands Used

```bash
# Set active project
firebase use btrips-42089

# Deploy Firestore rules
firebase deploy --only firestore:rules --project btrips-42089

# List Firebase apps
firebase apps:list --project btrips-42089

# Configure with FlutterFire (if needed)
flutterfire configure --project=btrips-42089
```

---

**Status**: ✅ FCM is fully configured and ready to use. All code-level setup is complete. Ensure Cloud Messaging API is enabled in Firebase Console.

