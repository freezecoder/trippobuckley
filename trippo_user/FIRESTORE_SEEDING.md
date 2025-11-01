# Firestore Data Seeding Guide

This guide explains how to seed Firestore with test data so that all application views can work properly for testing.

## Overview

The BTrips User app uses two main Firestore collections:

1. **`Drivers`** - Collection of available drivers (used by all authenticated users)
2. **User Email Collections** - Each user has a collection named after their email containing their ride requests/history

## Quick Start

### Method 1: Comprehensive Seed Script (Recommended) ⭐

Use the comprehensive seed script that adds both drivers and test ride data:

```bash
# Install dependencies (one-time)
pip install firebase-admin google-cloud-firestore

# Get service account key from Firebase Console
# Project Settings → Service Accounts → Generate New Private Key
# Save as serviceAccountKey.json in btrips_user directory

# Option 1: Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
python3 scripts/seed_firestore_data.py

# Option 2: Place serviceAccountKey.json in btrips_user directory
python3 scripts/seed_firestore_data.py

# Option 3: Seed rides for specific test user
export TEST_USER_EMAIL="your-test-user@example.com"
python3 scripts/seed_firestore_data.py
```

### Method 2: Drivers Only

If you only need to seed drivers:

```bash
python3 scripts/add_drivers.py
```

Or use the JavaScript version:

```bash
npm install firebase-admin
firebase login
firebase use btrips-42089
node scripts/add_drivers_simple.js
```

### Method 3: Firebase Console (Manual)

See `ADD_DRIVERS.md` for step-by-step manual instructions.

## Collections Structure

### 1. Drivers Collection

**Collection ID**: `Drivers`

**Document Structure**:
```javascript
{
  "Car Name": "Toyota Camry",           // Required: String
  "Car Plate Num": "ABC-1234",          // Required: String
  "Car Type": "Car",                    // Required: "Car", "SUV", or "MotorCycle"
  "name": "Ahmed Khan",                 // Required: String
  "email": "ahmed.khan@driver.com",     // Required: String (used as document ID)
  "driverStatus": "Idle",                // Required: "Idle", "Offline", or "On Trip"
  "driverLoc": {                         // Required: Map
    "geopoint": GeoPoint(40.6895, -74.1745)  // Required: GeoPoint
  }
}
```

**Status Values**:
- `"Idle"` - Driver is available for rides (shown on map)
- `"Offline"` - Driver is offline (not shown)
- `"On Trip"` - Driver is currently on a trip (not shown)

**Car Types**:
- `"Car"` - Standard car (sedan)
- `"SUV"` - SUV vehicle
- `"MotorCycle"` - Motorcycle

### 2. User Ride Requests Collection

**Collection ID**: User's email address (e.g., `test.user@example.com`)

**Document Structure** (each document represents a ride request):
```javascript
{
  "OriginLat": 40.6895,                    // Required: Number (latitude)
  "OriginLng": -74.1745,                   // Required: Number (longitude)
  "OriginAddress": "Newark Airport",        // Required: String
  "destinationLat": 40.7589,               // Required: Number (latitude)
  "destinationLng": -73.9851,             // Required: Number (longitude)
  "destinationAddress": "Times Square",     // Required: String
  "time": Timestamp,                        // Required: Timestamp (DateTime)
  "userEmail": "test.user@example.com",     // Required: String
  "driverEmail": "ahmed.khan@driver.com"    // Required: String (driver who accepted)
}
```

**Note**: The collection name must match the authenticated user's email address exactly.

## Data Needed for Testing Views

### Home Screen (Main Map View)

**Required Data**:
- ✅ At least 2-4 drivers in `Drivers` collection with:
  - `driverStatus` = `"Idle"`
  - Valid `driverLoc.geopoint`
  - Valid `Car Name`, `Car Type`, `name`, `email`

**What It Shows**:
- Driver markers on the map (for Idle drivers within 50km radius)
- Driver list when requesting a ride
- Fare calculation based on distance

### Ride Request Screen

**Required Data**:
- ✅ Same as Home Screen
- ✅ User must be authenticated (so Firestore rules allow access)

**What It Does**:
- Creates a new document in user's email collection
- Sends notification to selected driver

### Ride History View (if implemented)

**Required Data**:
- ✅ User's email collection with ride request documents
- ✅ Each document should have valid origin/destination coordinates and addresses

**What It Shows**:
- List of past rides
- Pickup and destination addresses
- Timestamp of each ride
- Driver who handled the ride

## Sample Test Data

The seed script (`seed_firestore_data.py`) includes:

### 4 Sample Drivers

1. **Ahmed Khan** - Toyota Camry (Car)
   - Location: Near Newark Airport (40.6895, -74.1745)
   - Email: ahmed.khan@driver.com

2. **Sara Ali** - Honda Civic (Car)
   - Location: Near JFK Airport (40.6413, -73.7781)
   - Email: sara.ali@driver.com

3. **Mohammed Hassan** - Toyota RAV4 (SUV)
   - Location: Near La Guardia Airport (40.7769, -73.8740)
   - Email: mohammed.hassan@driver.com

4. **Fatima Ahmed** - Yamaha R15 (MotorCycle)
   - Location: Near Philadelphia Airport (39.8719, -75.2411)
   - Email: fatima.ahmed@driver.com

### Sample Ride Requests (if TEST_USER_EMAIL is set)

4 sample rides from airports to NYC landmarks:
- Newark Airport → Times Square
- JFK Airport → Central Park
- LaGuardia Airport → Empire State Building
- Philadelphia Airport → Brooklyn Bridge

## Testing Checklist

Before testing views, ensure:

- [ ] Firebase project is set up (`btrips-42089`)
- [ ] Firestore security rules allow authenticated access (see `firestore.rules`)
- [ ] At least 2-4 drivers are seeded with `driverStatus = "Idle"`
- [ ] Drivers have valid GeoPoint coordinates
- [ ] User is authenticated in the app (to see drivers and make ride requests)
- [ ] For ride history: User's email collection has ride request documents

## Troubleshooting

### Drivers Not Showing on Map

1. **Check driver status**: Only drivers with `driverStatus = "Idle"` are shown
2. **Check coordinates**: Drivers must be within ~50km of user's location
3. **Check authentication**: User must be logged in (Firestore rules require auth)
4. **Check Firestore console**: Verify drivers exist and have correct structure

### Permission Denied Errors

1. **Check Firestore rules**: Ensure rules allow authenticated users to read `Drivers` collection
2. **Check authentication**: User must be logged in
3. **Check Firebase project**: Ensure using correct project (`btrips-42089`)

### Ride Requests Not Working

1. **Check user email**: Collection name must exactly match user's authenticated email
2. **Check Firestore rules**: Rules allow users to write to their own email collection
3. **Check fields**: All required fields must be present (see structure above)

## Security Rules

Current Firestore rules (in `firestore.rules`):

- ✅ Authenticated users can read all drivers
- ✅ Authenticated users can update driver status
- ✅ Users can only read/write their own email collection
- ✅ Drivers can create/update their own driver document

**Important**: The seed script bypasses normal rules by using Admin SDK. In production, ensure rules are properly configured.

## Next Steps

1. Run the seed script to populate test data
2. Create a test user account in Firebase Authentication
3. Log in to the app with test user credentials
4. Test the Home screen to see drivers on map
5. Test ride request flow
6. Test ride history (if user email collection has data)

## Related Files

- `scripts/seed_firestore_data.py` - Comprehensive seed script
- `scripts/add_drivers.py` - Drivers-only seed script
- `scripts/add_drivers_simple.js` - JavaScript version
- `firestore.rules` - Firestore security rules
- `ADD_DRIVERS.md` - Quick driver setup guide

