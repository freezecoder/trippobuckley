# Adding Drivers to Firestore

## 🚀 Quick Method (Using Firebase CLI) - RECOMMENDED ⭐

The easiest method - uses Firebase CLI (which you likely already have):

### Setup (One-time):
```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Select your project
firebase use btrips-42089
```

### Run:
```bash
./scripts/add_drivers.sh
```

That's it! 4 drivers will be added automatically.

**Note**: See `scripts/SETUP_DRIVERS.md` for other methods.

---

## Alternative: Python Script

The easiest way is to use the Python script:

### Setup (One-time):
```bash
# Install dependencies
pip install firebase-admin google-cloud-firestore

# Get service account key from Firebase Console
# Project Settings → Service Accounts → Generate New Private Key
# Save as serviceAccountKey.json

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
```

### Run:
```bash
python3 scripts/add_drivers.py
```

That's it! 4 drivers will be added automatically.

**Note**: If you don't want to set up Python, use the Firebase Console method below.

---

## Alternative Methods

A script is available to add 4 sample drivers to Firestore.

### Option 1: Using Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `btrips-42089`
3. Navigate to **Firestore Database**
4. Click **Start collection** (if first time) or use existing **Drivers** collection
5. Add documents with the following structure:

#### Driver 1: Ahmed Khan
- **Collection ID**: `Drivers`
- **Document ID**: `ahmed.khan@driver.com`
- **Fields**:
  ```
  Car Name: "Toyota Camry"
  Car Plate Num: "ABC-1234"
  Car Type: "Car"
  name: "Ahmed Khan"
  email: "ahmed.khan@driver.com"
  driverStatus: "Idle"
  driverLoc (Map):
    geopoint (GeoPoint): latitude: 40.6895, longitude: -74.1745
  ```

#### Driver 2: Sara Ali
- **Document ID**: `sara.ali@driver.com`
- **Fields**:
  ```
  Car Name: "Honda Civic"
  Car Plate Num: "XYZ-5678"
  Car Type: "Car"
  name: "Sara Ali"
  email: "sara.ali@driver.com"
  driverStatus: "Idle"
  driverLoc (Map):
    geopoint (GeoPoint): latitude: 40.6413, longitude: -73.7781
  ```

#### Driver 3: Mohammed Hassan
- **Document ID**: `mohammed.hassan@driver.com`
- **Fields**:
  ```
  Car Name: "Toyota RAV4"
  Car Plate Num: "SUV-9012"
  Car Type: "SUV"
  name: "Mohammed Hassan"
  email: "mohammed.hassan@driver.com"
  driverStatus: "Idle"
  driverLoc (Map):
    geopoint (GeoPoint): latitude: 40.7769, longitude: -73.8740
  ```

#### Driver 4: Fatima Ahmed
- **Document ID**: `fatima.ahmed@driver.com`
- **Fields**:
  ```
  Car Name: "Yamaha R15"
  Car Plate Num: "MOT-3456"
  Car Type: "MotorCycle"
  name: "Fatima Ahmed"
  email: "fatima.ahmed@driver.com"
  driverStatus: "Idle"
  driverLoc (Map):
    geopoint (GeoPoint): latitude: 39.8719, longitude: -75.2411
  ```

### Option 2: Using Script (Requires Firebase Admin)

1. Temporarily update Firestore rules to allow script writes (already done)
2. Run the script:
   ```bash
   cd btrips_user
   flutter run -d chrome scripts/add_drivers.dart
   ```
   OR if you have dart directly:
   ```bash
   dart run scripts/add_drivers.dart
   ```

## Important Notes

1. **GeoPoint Format**: When adding via Firebase Console, use the GeoPoint type (not a regular number)
   - Click the dropdown next to "driverLoc" → Select "map"
   - Add field "geopoint" → Select type "geopoint"
   - Enter latitude and longitude

2. **Driver Status**: Must be "Idle" (capital I) for drivers to appear as available

3. **Car Types**: Must be exactly one of:
   - "Car"
   - "SUV"
   - "MotorCycle"

4. **Location Coordinates**:
   - Driver 1: Near Newark Airport (40.6895, -74.1745)
   - Driver 2: Near JFK Airport (40.6413, -73.7781)
   - Driver 3: Near La Guardia Airport (40.7769, -73.8740)
   - Driver 4: Near Philadelphia Airport (39.8719, -75.2411)

5. **Security Rules**: The current rules allow authenticated users to read drivers. For testing, you may need to temporarily allow writes, or use Firebase Admin SDK.

## Verifying Drivers

After adding, check in your app:
1. Set a pickup location
2. Click "Request a ride"
3. You should see the available drivers in the list

