# Database Scripts

Easy-to-use Python scripts for managing Firestore data.

## Setup

### 1. Install Python Dependencies

```bash
pip install -r scripts/requirements.txt
```

Or install individually:
```bash
pip install firebase-admin google-cloud-firestore
```

### 2. Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `btrips-42089`
3. Click ⚙️ **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Save the JSON file (e.g., `serviceAccountKey.json`)
7. **IMPORTANT**: Add this file to `.gitignore` (never commit it!)

### 3. Set Environment Variable

```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
```

Or on Windows:
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
```

## Scripts

### Add Drivers (`add_drivers.py`)

Adds 4 sample drivers to Firestore.

```bash
python3 scripts/add_drivers.py
```

**Drivers Added:**
1. Ahmed Khan - Toyota Camry (Car) - Near Newark Airport
2. Sara Ali - Honda Civic (Car) - Near JFK Airport
3. Mohammed Hassan - Toyota RAV4 (SUV) - Near La Guardia Airport
4. Fatima Ahmed - Yamaha R15 (MotorCycle) - Near Philadelphia Airport

**Output:**
```
✅ Added: Ahmed Khan (Toyota Camry)
   📧 Email: ahmed.khan@driver.com
   🚗 Type: Car
   📍 Location: 40.6895, -74.1745
   🟢 Status: Idle
```

## Alternative: Firebase Console (No Setup Needed)

If you don't want to use Python, you can manually add drivers via Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select **Firestore Database**
3. Click **Start collection** or use existing **Drivers** collection
4. Add documents (see `ADD_DRIVERS.md` for details)

## Troubleshooting

### "Could not initialize Firebase Admin SDK"
- Make sure `GOOGLE_APPLICATION_CREDENTIALS` is set correctly
- Verify the service account key file exists and is valid
- Check that you have the correct project ID

### "Permission denied"
- Make sure Firestore security rules allow writes (see `firestore.rules`)
- Or use Firebase Console which bypasses security rules

### "Module not found"
- Run: `pip install firebase-admin google-cloud-firestore`

