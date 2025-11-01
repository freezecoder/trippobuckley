# FCM CORS Error Fix & Cloud Functions Guide

**Date**: November 1, 2025  
**Status**: ✅ **CORS ERROR FIXED** (Notifications disabled temporarily)

---

## 🐛 The Error

```
Access to XMLHttpRequest at 'https://fcm.googleapis.com/fcm/send' 
from origin 'http://localhost:8080' has been blocked by CORS policy: 
Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

---

## 🔍 What Caused This?

### The Problem
The app was trying to send FCM (Firebase Cloud Messaging) notifications **directly from the web browser** to Firebase's FCM API:

```dart
// ❌ WRONG: Calling FCM API from client-side
await Dio().post("https://fcm.googleapis.com/fcm/send",
  options: Options(headers: {
    HttpHeaders.authorizationHeader: "Bearer YOUR_SERVER_KEY"
  }),
  data: {...}
);
```

### Why It Doesn't Work

1. **CORS Policy**: Browsers block cross-origin requests to FCM for security
2. **Server Key Exposure**: FCM server keys should NEVER be in client-side code
3. **Security Risk**: Anyone can inspect your code and steal the server key

---

## ✅ The Fix

### Immediate Fix (Current)
**Disabled the direct FCM calls** to allow ride requests to complete:

```dart
Future<dynamic> sendNotificationToDriver(...) async {
  // TODO: Implement FCM notifications via Cloud Functions
  print('ℹ️ Notification skipped (requires Cloud Functions)');
  
  /* DISABLED: Direct FCM calls don't work from browser (CORS) */
}
```

**Result**: 
- ✅ Ride requests now work without CORS errors
- ✅ No server key exposed in client code
- ⚠️ Notifications temporarily disabled (need Cloud Functions)

---

## 🚀 Proper Solution: Firebase Cloud Functions

### Architecture

```
User requests ride
    ↓
Client writes to Firestore (rideRequests collection)
    ↓
Cloud Function triggered by Firestore write
    ↓
Cloud Function sends FCM notification
    ↓
Driver receives notification
```

### Benefits
- ✅ No CORS issues (backend to FCM)
- ✅ Server key stays secure (only on backend)
- ✅ Scalable and reliable
- ✅ Works on all platforms (web, iOS, Android)

---

## 📝 Implementation Steps

### Step 1: Install Firebase Tools

```bash
npm install -g firebase-tools
firebase login
```

### Step 2: Initialize Cloud Functions

```bash
cd /Users/azayed/aidev/trippobuckley/trippo_user
firebase init functions
```

Select:
- Language: TypeScript or JavaScript
- ESLint: Yes
- Install dependencies: Yes

### Step 3: Create Cloud Function

**File**: `functions/src/index.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Trigger when a ride request is created
export const onRideRequestCreated = functions.firestore
  .document('rideRequests/{rideId}')
  .onCreate(async (snapshot, context) => {
    const rideData = snapshot.data();
    
    // Only send notification for pending rides
    if (rideData.status !== 'pending') {
      return null;
    }

    // Get driver's FCM token from drivers collection
    // For now, send to all online drivers nearby
    const driversSnapshot = await admin.firestore()
      .collection('drivers')
      .where('driverStatus', '==', 'Idle')
      .limit(10)
      .get();

    const tokens: string[] = [];
    driversSnapshot.forEach(doc => {
      const fcmToken = doc.data().fcmToken;
      if (fcmToken) {
        tokens.push(fcmToken);
      }
    });

    if (tokens.length === 0) {
      console.log('No online drivers to notify');
      return null;
    }

    // Create notification message
    const message = {
      notification: {
        title: 'New Ride Request',
        body: `Pickup: ${rideData.pickupAddress}\nDestination: ${rideData.dropoffAddress}`,
      },
      data: {
        rideId: context.params.rideId,
        pickupLat: rideData.pickupLocation.latitude.toString(),
        pickupLng: rideData.pickupLocation.longitude.toString(),
        fare: rideData.fare.toString(),
      },
    };

    // Send to multiple tokens
    const response = await admin.messaging().sendMulticast({
      tokens: tokens,
      ...message,
    });

    console.log(`Sent notifications to ${response.successCount} drivers`);
    return response;
  });

// Trigger when ride is accepted
export const onRideAccepted = functions.firestore
  .document('rideRequests/{rideId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if status changed to accepted
    if (before.status !== 'accepted' && after.status === 'accepted') {
      // Get user's FCM token
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(after.userId)
        .get();

      const fcmToken = userDoc.data()?.fcmToken;
      if (!fcmToken) {
        console.log('User has no FCM token');
        return null;
      }

      // Send notification to user
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'Ride Accepted!',
          body: 'Your driver is on the way',
        },
        data: {
          rideId: context.params.rideId,
          driverId: after.driverId,
        },
      });

      console.log('Notified user about ride acceptance');
    }

    return null;
  });

// Trigger when driver arrives
export const onDriverArrived = functions.firestore
  .document('rideRequests/{rideId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if driver arrived (custom field you'd add)
    if (!before.driverArrived && after.driverArrived) {
      // Get user's FCM token
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(after.userId)
        .get();

      const fcmToken = userDoc.data()?.fcmToken;
      if (!fcmToken) {
        return null;
      }

      // Send notification
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'Driver Arrived',
          body: 'Your driver is waiting for you',
        },
        data: {
          rideId: context.params.rideId,
        },
      });
    }

    return null;
  });
```

### Step 4: Deploy Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Step 5: Update Client Code

Remove the old direct FCM calls (already done ✅) and just write to Firestore:

```dart
// ✅ CORRECT: Just write to Firestore
await db.collection('rideRequests').add({
  userId: auth.currentUser!.uid,
  status: "pending",
  // ... other fields
});

// Cloud Function will automatically send notification!
```

---

## 🎯 Testing Cloud Functions

### Test Locally (Emulator)

```bash
firebase emulators:start --only functions,firestore
```

Then test from your app using the emulator.

### Test in Production

1. Deploy functions: `firebase deploy --only functions`
2. Create a ride request from the app
3. Check Firebase Console → Functions logs
4. Check if notification was sent

### View Logs

```bash
firebase functions:log
```

Or in Firebase Console:
https://console.firebase.google.com/project/trippo-42089/functions/logs

---

## 📱 Client-Side FCM Setup

### Store FCM Tokens

When user logs in, save their FCM token:

```dart
// Get FCM token
final fcmToken = await FirebaseMessaging.instance.getToken();

// Save to Firestore
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({'fcmToken': fcmToken});
```

### Handle Notifications

```dart
// In main.dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Got a message whilst in the foreground!');
  print('Message data: ${message.data}');

  if (message.notification != null) {
    // Show local notification
    showNotification(message.notification!);
  }
});
```

---

## 🔐 Security

### Never Expose Server Keys

```dart
// ❌ BAD: Server key in client code
"Bearer AAAA7vDmw2Y:APA91b..."

// ✅ GOOD: Server key only in Cloud Functions
// (automatically handled by Firebase Admin SDK)
```

### Firestore Security Rules

```javascript
// Only allow users to update their own FCM tokens
match /users/{userId} {
  allow update: if request.auth.uid == userId && 
                   request.resource.data.diff(resource.data)
                   .affectedKeys().hasOnly(['fcmToken']);
}
```

---

## 💰 Costs

### Cloud Functions Pricing (Free Tier)
- 2 million invocations/month
- 400,000 GB-seconds, 200,000 GHz-seconds of compute time
- 5 GB network egress per month

For a ride-sharing app:
- ~1-2 function calls per ride request
- Should stay within free tier for development/testing

### FCM Pricing
- **Free** for unlimited messages!

---

## 🧪 Current Status

### What Works ✅
- Ride requests submit without CORS errors
- Ride data saves to Firestore
- App doesn't crash

### What's Disabled ⏸️
- FCM notifications (temporarily)
- Driver notifications about new rides
- User notifications about ride acceptance

### To Implement ⏳
1. Set up Cloud Functions
2. Deploy notification functions
3. Store FCM tokens for users/drivers
4. Test end-to-end notification flow

---

## 📚 Resources

### Firebase Documentation
- [Cloud Functions Guide](https://firebase.google.com/docs/functions)
- [FCM Overview](https://firebase.google.com/docs/cloud-messaging)
- [Admin SDK](https://firebase.google.com/docs/admin/setup)

### Tutorials
- [Send FCM from Cloud Functions](https://firebase.google.com/docs/functions/use-cases#notify_users_when_something_interesting_happens)
- [Firestore Triggers](https://firebase.google.com/docs/functions/firestore-events)

---

## 🎯 Next Steps

### Immediate (App Works)
- ✅ Ride requests work
- ✅ No CORS errors
- ✅ Data saves to Firebase

### Soon (Notifications)
1. Initialize Cloud Functions project
2. Implement notification triggers
3. Deploy to Firebase
4. Store FCM tokens on login
5. Test notification flow

### Future (Enhanced)
- Location-based driver selection
- Push notification icons/images
- Notification actions (Accept/Reject)
- Analytics on notification delivery

---

**Status**: 🟢 **RIDE REQUESTS WORKING** (Notifications to be implemented via Cloud Functions)  
**Priority**: Medium (not blocking core functionality)  
**Effort**: 2-3 hours to implement Cloud Functions properly


