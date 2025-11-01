# Adding Drivers to Firestore - Easy Methods

## Method 1: Firebase CLI (Easiest) ⭐

### Setup (one-time):
```bash
# Install Firebase CLI
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

That's it! The script will add all 4 drivers automatically.

---

## Method 2: FlutterFire CLI

If you already have FlutterFire CLI set up:

```bash
# Make sure you're in the project
cd btrips_user

# Use FlutterFire to add data (requires custom command or use method 1)
```

**Note**: FlutterFire CLI is primarily for configuring Firebase in your Flutter app, not for adding data. Method 1 (Firebase CLI) is better for data operations.

---

## Method 3: Python Script (If you prefer Python)

```bash
# Install dependencies
pip install firebase-admin google-cloud-firestore

# Get service account key from Firebase Console
# Project Settings → Service Accounts → Generate New Private Key
# Save as serviceAccountKey.json

# Run
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
python3 scripts/add_drivers.py
```

---

## Method 4: Firebase Console (No Setup Needed)

1. Go to [Firebase Console](https://console.firebase.google.com/project/btrips-42089/firestore)
2. Click **Start collection** (or use existing **Drivers** collection)
3. Add documents manually (see details below)

### Driver Details to Add:

#### Driver 1
- **Document ID**: `ahmed.khan@driver.com`
- **Fields**:
  - `Car Name`: "Toyota Camry"
  - `Car Plate Num`: "ABC-1234"
  - `Car Type`: "Car"
  - `name`: "Ahmed Khan"
  - `email`: "ahmed.khan@driver.com"
  - `driverStatus`: "Idle"
  - `driverLoc` (Map):
    - `geopoint` (GeoPoint): 40.6895, -74.1745

#### Driver 2
- **Document ID**: `sara.ali@driver.com`
- **Fields**: Similar structure, use data from `scripts/add_drivers.py` or `ADD_DRIVERS.md`

---

## Recommended: Use Method 1 (Firebase CLI)

It's the simplest and doesn't require any service account keys or additional setup if you already have Firebase CLI installed for your project.

