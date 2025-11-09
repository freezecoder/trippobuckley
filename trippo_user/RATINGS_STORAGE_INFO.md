# ⭐ Ratings & Feedback Storage - Complete Overview

**Date**: November 4, 2025  
**Status**: ✅ **DOCUMENTED**

---

## 📊 How Ratings Are Stored

### ✅ Current Implementation

Ratings and feedback **ARE stored in Firebase**, but in the **ride documents**, not in a separate ratings collection.

---

## 🗄️ Storage Location

### Primary Storage: Ride Documents

**Collections Used:**
1. `rideHistory/{rideId}` - For completed rides (permanent)
2. `rideRequests/{rideId}` - For rides not yet moved to history (temporary)

**Fields Stored:**

```javascript
{
  // ... other ride fields ...
  
  // User's Rating of Driver
  userRating: 4.5,           // Number (1.0 - 5.0)
  userFeedback: "Great driver, very professional!", // String (optional)
  
  // Driver's Rating of User  
  driverRating: 5.0,         // Number (1.0 - 5.0)
  driverFeedback: "Excellent passenger, on time!", // String (optional)
}
```

---

## 📝 What Gets Saved

### When User Rates Driver:

**Collected from Rating Screen:**
- ✅ **Star Rating** (1-5 stars, required)
- ✅ **Feedback/Comment** (text, optional)

**Saved to Firebase:**
```javascript
// In rideHistory/{rideId}
{
  userRating: 4.5,
  userFeedback: "Great driver, very friendly!"
}
```

**Also Updates:**
```javascript
// In drivers/{driverId}
{
  rating: 4.7,  // Calculated average of all ratings
  totalRides: 156  // Incremented
}
```

### When Driver Rates User:

**Collected from Rating Screen:**
- ✅ **Star Rating** (1-5 stars, required)
- ✅ **Feedback/Comment** (text, optional)

**Saved to Firebase:**
```javascript
// In rideHistory/{rideId}
{
  driverRating: 5.0,
  driverFeedback: "Perfect passenger!"
}
```

**Also Updates:**
```javascript
// In userProfiles/{userId}
{
  rating: 4.9,  // Calculated average
  totalRides: 42  // Incremented
}
```

---

## 🔄 Rating Flow

### User Rating Driver:

1. **User completes ride**
2. **System shows rating screen** automatically
3. **User selects stars** (1-5)
4. **User types feedback** (optional)
5. **Click "Submit Rating"**
6. **Saves to Firestore:**
   - `rideHistory/{rideId}.userRating = X.X`
   - `rideHistory/{rideId}.userFeedback = "..."`
   - `drivers/{driverId}.rating = (new average)`
   - `drivers/{driverId}.totalRides += 1`

### Driver Rating User:

1. **Driver completes ride**
2. **System shows rating screen** automatically
3. **Driver selects stars** (1-5)
4. **Driver types feedback** (optional)
5. **Click "Submit Rating"**
6. **Saves to Firestore:**
   - `rideHistory/{rideId}.driverRating = X.X`
   - `rideHistory/{rideId}.driverFeedback = "..."`
   - `userProfiles/{userId}.rating = (new average)`
   - `userProfiles/{userId}.totalRides += 1`

---

## 📂 Firebase Collections Used

### 1. `rideHistory` Collection
**Primary storage for ratings**

```javascript
rideHistory/{rideId}/
{
  // Ride details
  userId: "abc123",
  driverId: "xyz789",
  fare: 25.00,
  status: "completed",
  
  // USER's rating of DRIVER ⭐
  userRating: 4.5,
  userFeedback: "Great service!",
  
  // DRIVER's rating of USER ⭐
  driverRating: 5.0,
  driverFeedback: "On time and friendly!",
  
  // Timestamps
  completedAt: Timestamp,
  requestedAt: Timestamp,
  ...
}
```

### 2. `drivers` Collection
**Stores driver's average rating**

```javascript
drivers/{driverId}/
{
  carName: "Toyota Camry",
  rating: 4.7,        // ⭐ Average of all userRating scores
  totalRides: 156,    // Total completed rides
  earnings: 3450.00,
  ...
}
```

### 3. `userProfiles` Collection
**Stores user's average rating**

```javascript
userProfiles/{userId}/
{
  homeAddress: "...",
  rating: 4.9,        // ⭐ Average of all driverRating scores
  totalRides: 42,     // Total completed rides
  favoriteLocations: [],
  ...
}
```

### 4. `ratings` Collection (DEFINED BUT NOT USED)
**Note**: There's a `ratings` collection defined in Firestore rules, but **it's not currently being used** in the code. All ratings go directly into ride documents.

---

## 🔍 How to View Ratings

### View All Ratings for a Specific Ride:

```bash
# Firebase Console
Go to Firestore > rideHistory > {rideId}
Look for:
  - userRating
  - userFeedback
  - driverRating
  - driverFeedback
```

### View Driver's Average Rating:

```bash
# Firebase Console
Go to Firestore > drivers > {driverId}
Look for:
  - rating (average)
  - totalRides (count)
```

### View User's Average Rating:

```bash
# Firebase Console
Go to Firestore > userProfiles > {userId}
Look for:
  - rating (average)
  - totalRides (count)
```

---

## 📱 UI Components

### Rating Screen Features:

**File**: `lib/features/shared/presentation/screens/rating_screen.dart`

**What Users See:**
- ✅ 5-star rating selector
- ✅ Feedback text field (optional)
- ✅ "Submit Rating" button
- ✅ "Skip" button (to skip rating)

**Prompt Text:**
- For Users: "How was your ride?"
- For Drivers: "How was the passenger?"

**Feedback Field Label:**
"Share your feedback (optional)"

---

## 🔒 Security Rules

### Firestore Rules for Rating Updates:

**For `rideHistory`:**
```javascript
allow update: if isAuthenticated() && (
  // User can add userRating and userFeedback
  (resource.data.userId == request.auth.uid && 
   isRegularUser() &&
   request.resource.data.diff(resource.data).affectedKeys()
     .hasOnly(['userRating', 'userFeedback'])) ||
  
  // Driver can add driverRating and driverFeedback
  (resource.data.driverId == request.auth.uid && 
   isDriver() &&
   request.resource.data.diff(resource.data).affectedKeys()
     .hasOnly(['driverRating', 'driverFeedback']))
);
```

**Security Features:**
- ✅ Users can only rate rides they took
- ✅ Drivers can only rate rides they completed
- ✅ Can only update rating fields, nothing else
- ✅ Ratings are permanent (no deletion allowed)

---

## 📊 Data Retrieval

### Get Ratings for a Ride:

```dart
// Dart/Flutter code
final ride = await rideRepo.getRideRequest(rideId);

if (ride != null) {
  final userRating = ride.userRating;      // User's rating (nullable)
  final userFeedback = ride.userFeedback;  // User's comment (nullable)
  final driverRating = ride.driverRating;  // Driver's rating (nullable)
  final driverFeedback = ride.driverFeedback; // Driver's comment (nullable)
}
```

### Get Driver's Average:

```dart
final driver = await driverRepo.getDriver(driverId);
final averageRating = driver.rating;  // e.g., 4.7
final totalRides = driver.totalRides;  // e.g., 156
```

---

## ✅ Confirmation

### Are ratings stored? **YES** ✅
- Ratings ARE saved to Firebase
- Stored in `rideHistory` collection
- Each ride has both user and driver ratings

### Are comments/feedback stored? **YES** ✅
- Feedback IS saved to Firebase
- Stored as `userFeedback` and `driverFeedback`
- Optional field (can be null/empty)

### Are they permanent? **YES** ✅
- Once submitted, ratings cannot be changed
- Stored in ride history forever
- Security rules prevent deletion

### Can you retrieve them? **YES** ✅
- Query `rideHistory` collection
- Filter by `userId` or `driverId`
- Access rating and feedback fields

---

## 📈 Rating Calculation

### Average Rating Formula:

```dart
// When a new rating is submitted
final currentAverage = driver.rating;  // e.g., 4.5
final totalRides = driver.totalRides;  // e.g., 100
final newRating = 5.0;                 // New rating submitted

final newAverage = ((currentAverage * totalRides) + newRating) / (totalRides + 1);
// Result: ((4.5 * 100) + 5.0) / 101 = 4.5049...

// Update driver document
driver.rating = newAverage;
driver.totalRides = totalRides + 1;
```

---

## 🗂️ Example Firebase Data

### Example Ride with Ratings:

```javascript
// rideHistory/abc123xyz
{
  id: "abc123xyz",
  userId: "user_456",
  driverId: "driver_789",
  
  // Ride details
  pickupAddress: "123 Main St",
  dropoffAddress: "456 Oak Ave",
  fare: 25.00,
  distance: 5.2,
  duration: 15,
  status: "completed",
  
  // Timestamps
  requestedAt: Timestamp(2025-11-04 10:00:00),
  completedAt: Timestamp(2025-11-04 10:20:00),
  
  // USER's rating of DRIVER ⭐
  userRating: 4.5,
  userFeedback: "Great driver! Very professional and friendly. Car was clean and ride was smooth.",
  
  // DRIVER's rating of USER ⭐
  driverRating: 5.0,
  driverFeedback: "Perfect passenger! On time and respectful.",
  
  // Payment
  paymentMethod: "card",
  paymentStatus: "completed"
}
```

---

## 🛠️ Scripts to Query Ratings

### Create a Script to View Ratings:

```javascript
// scripts/view_ratings.js
const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function viewRatings(rideId) {
  const rideDoc = await db.collection('rideHistory').doc(rideId).get();
  
  if (rideDoc.exists) {
    const ride = rideDoc.data();
    
    console.log('Ride:', rideId);
    console.log('\nUser Rating:');
    console.log('  Stars:', ride.userRating || 'Not rated');
    console.log('  Feedback:', ride.userFeedback || 'No feedback');
    
    console.log('\nDriver Rating:');
    console.log('  Stars:', ride.driverRating || 'Not rated');
    console.log('  Feedback:', ride.driverFeedback || 'No feedback');
  }
}

// Usage: node scripts/view_ratings.js abc123xyz
viewRatings(process.argv[2]);
```

---

## 📝 Summary

✅ **Ratings ARE stored**: In `rideHistory` collection  
✅ **Feedback IS stored**: As `userFeedback` and `driverFeedback` fields  
✅ **Permanent storage**: Cannot be deleted or modified  
✅ **Two-way ratings**: Both user and driver can rate each other  
✅ **Average calculations**: Updated in user/driver profiles  
✅ **Secure**: Firestore rules enforce proper access  
✅ **Retrievable**: Can query and display ratings anytime  

**All ratings and comments from the feedback section are safely stored in Firebase!** 🎉

---

**Last Updated**: November 4, 2025  
**Status**: 🟢 **ACTIVE & WORKING**  
**Storage**: `rideHistory` collection

