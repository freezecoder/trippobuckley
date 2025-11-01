# Ratings Collection Schema

**Created**: November 1, 2025  
**Purpose**: Dedicated collection for storing all ratings (driver-to-user and user-to-driver)

---

## Collection Structure

```javascript
ratings/
  {ratingId}/
    ├── ratingType: "driver-to-user" | "user-to-driver"
    ├── rideId: string              // Reference to the ride
    ├── ratedBy: string             // User ID of rater
    ├── ratedByEmail: string        // Email of rater
    ├── ratedUser: string           // User ID being rated
    ├── ratedUserEmail: string      // Email being rated
    ├── rating: number              // 1-5 stars
    ├── feedback: string            // Optional feedback text
    ├── createdAt: Timestamp        // When rating was given
    ├── pickupAddress: string       // For context
    ├── dropoffAddress: string      // For context
    └── fare: number                // Ride fare for context
```

---

## Rating Types

### 1. Driver-to-User (Passenger)
```javascript
{
  ratingType: "driver-to-user",
  rideId: "abc123",
  ratedBy: "driverId",
  ratedByEmail: "driver@example.com",
  ratedUser: "userId",
  ratedUserEmail: "user@example.com",
  rating: 4.5,
  feedback: "Great passenger! Very polite and on time.",
  createdAt: Timestamp,
  pickupAddress: "123 Main St",
  dropoffAddress: "456 Oak Ave",
  fare: 15.50
}
```

### 2. User-to-Driver
```javascript
{
  ratingType: "user-to-driver",
  rideId: "abc123",
  ratedBy: "userId",
  ratedByEmail: "user@example.com",
  ratedUser: "driverId",
  ratedUserEmail: "driver@example.com",
  rating: 5.0,
  feedback: "Excellent driver! Safe and friendly.",
  createdAt: Timestamp,
  pickupAddress: "123 Main St",
  dropoffAddress: "456 Oak Ave",
  fare: 15.50
}
```

---

## Benefits

### 1. Better Organization
- All ratings in one place
- Easy to query by user or driver
- Historical rating data preserved

### 2. Analytics Capabilities
```javascript
// Average rating for a driver
ratings.where('ratedUser', '==', driverId)
      .where('ratingType', '==', 'user-to-driver')
      
// All ratings given by a driver
ratings.where('ratedBy', '==', driverId)
      .where('ratingType', '==', 'driver-to-user')

// Recent ratings
ratings.orderBy('createdAt', 'desc').limit(10)
```

### 3. Data Integrity
- Immutable rating records
- Audit trail
- Can detect rating patterns/fraud

### 4. Flexible Queries
- Get all ratings for a user (as passenger)
- Get all ratings by a user (as rater)
- Get ratings for specific time periods
- Calculate trends

---

## Security Rules

```javascript
match /ratings/{ratingId} {
  // Anyone authenticated can read ratings
  allow read: if isAuthenticated();
  
  // Only the person who gave the rating can create it
  allow create: if isAuthenticated() && 
                  request.resource.data.ratedBy == request.auth.uid &&
                  // Must be either driver rating user OR user rating driver
                  (
                    (request.resource.data.ratingType == 'driver-to-user' && isDriver()) ||
                    (request.resource.data.ratingType == 'user-to-driver' && isRegularUser())
                  );
  
  // Ratings are immutable (can't be updated)
  allow update: if false;
  
  // Only admins can delete (handled separately)
  allow delete: if false;
}
```

---

## Composite Indexes Required

Add to `firestore.indexes.json`:

```json
{
  "collectionGroup": "ratings",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "ratedUser",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
},
{
  "collectionGroup": "ratings",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "ratedBy",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
},
{
  "collectionGroup": "ratings",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "ratingType",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "ratedUser",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
}
```

---

## Usage Examples

### Creating a Rating (Driver rates User)

```javascript
await db.collection('ratings').add({
  ratingType: 'driver-to-user',
  rideId: rideId,
  ratedBy: currentUser.uid,
  ratedByEmail: currentUser.email,
  ratedUser: ride.userId,
  ratedUserEmail: ride.userEmail,
  rating: 4.5,
  feedback: 'Great passenger!',
  createdAt: FieldValue.serverTimestamp(),
  pickupAddress: ride.pickupAddress,
  dropoffAddress: ride.dropoffAddress,
  fare: ride.fare,
});
```

### Querying Ratings

```javascript
// Get all ratings received by a driver
const driverRatings = await db.collection('ratings')
  .where('ratedUser', '==', driverId)
  .where('ratingType', '==', 'user-to-driver')
  .orderBy('createdAt', 'desc')
  .get();

// Calculate average rating
const ratings = driverRatings.docs.map(doc => doc.data().rating);
const average = ratings.reduce((a, b) => a + b, 0) / ratings.length;
```

### Get Recent Ratings

```javascript
// Get last 10 ratings for a user (as passenger)
const recentRatings = await db.collection('ratings')
  .where('ratedUser', '==', userId)
  .where('ratingType', '==', 'driver-to-user')
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get();
```

---

## Migration Plan

### Phase 1: Add Collection (Non-Breaking)
1. Deploy new security rules with ratings collection
2. Deploy Firestore indexes
3. Keep existing rating fields in rideHistory

### Phase 2: Dual Write (Transition)
1. Update app to write to BOTH:
   - rideHistory (for backward compatibility)
   - ratings collection (new system)

### Phase 3: Switch to Read from Ratings
1. Update app to read from ratings collection
2. Keep writing to both

### Phase 4: Remove Old System (Future)
1. Stop writing to rideHistory ratings
2. Keep ratings collection as source of truth

---

## Integration with Existing Code

### Update Rating Functions

**Before**:
```dart
// Only updates rideHistory
await rideRepo.addDriverRating(
  rideId: rideId,
  rating: rating,
  feedback: feedback,
);
```

**After**:
```dart
// Updates both rideHistory AND ratings collection
await ratingsRepo.addDriverRating(
  rideId: rideId,
  ride: ride,
  rating: rating,
  feedback: feedback,
);
```

---

## Advantages Over Current System

| Feature | Current (rideHistory) | New (ratings collection) |
|---------|----------------------|--------------------------|
| Query all driver ratings | ❌ Need to scan all rides | ✅ Direct query |
| Rating history | ❌ Mixed with ride data | ✅ Dedicated collection |
| Analytics | ⚠️ Complex queries | ✅ Easy aggregation |
| Scalability | ⚠️ Large ride documents | ✅ Separate, indexed |
| Audit trail | ⚠️ Can be modified | ✅ Immutable records |
| Performance | ⚠️ Slower with growth | ✅ Fast, indexed queries |

---

## Next Steps

1. ✅ Define schema (this document)
2. ⏳ Update `firestore.rules` to include ratings collection
3. ⏳ Update `firestore.indexes.json` to add composite indexes
4. ⏳ Deploy rules and indexes
5. ⏳ Create RatingsRepository in app
6. ⏳ Update rating screens to use new repository
7. ⏳ Create migration script for existing ratings
8. ⏳ Test thoroughly

---

**Status**: Schema defined, ready for implementation  
**Last Updated**: November 1, 2025

