# Quick Guide: Add Drivers via Firebase Console

Since Firebase CLI doesn't have direct Firestore write commands, here's the **fastest way**:

## Step 1: Open Firebase Console
Go to: https://console.firebase.google.com/project/btrips-42089/firestore

## Step 2: Add Collection (if needed)
1. Click **Start collection** (or click existing **Drivers** collection)
2. Collection ID: `Drivers`

## Step 3: Add Each Driver

For each driver, click **Add document**:

### Driver 1: Ahmed Khan
- **Document ID**: `ahmed.khan@driver.com`
- **Fields** (click "Add field" for each):
  - Field: `Car Name`, Type: `string`, Value: `Toyota Camry`
  - Field: `Car Plate Num`, Type: `string`, Value: `ABC-1234`
  - Field: `Car Type`, Type: `string`, Value: `Car`
  - Field: `name`, Type: `string`, Value: `Ahmed Khan`
  - Field: `email`, Type: `string`, Value: `ahmed.khan@driver.com`
  - Field: `driverStatus`, Type: `string`, Value: `Idle`
  - Field: `driverLoc`, Type: `map`, then add:
    - Field: `geopoint`, Type: `geopoint`, Value: `40.6895, -74.1745`

### Driver 2: Sara Ali
- **Document ID**: `sara.ali@driver.com`
- Same structure, values:
  - `Car Name`: `Honda Civic`
  - `Car Plate Num`: `XYZ-5678`
  - `Car Type`: `Car`
  - `name`: `Sara Ali`
  - `email`: `sara.ali@driver.com`
  - `driverStatus`: `Idle`
  - `driverLoc.geopoint`: `40.6413, -73.7781`

### Driver 3: Mohammed Hassan
- **Document ID**: `mohammed.hassan@driver.com`
- Values:
  - `Car Name`: `Toyota RAV4`
  - `Car Plate Num`: `SUV-9012`
  - `Car Type`: `SUV`
  - `name`: `Mohammed Hassan`
  - `email`: `mohammed.hassan@driver.com`
  - `driverStatus`: `Idle`
  - `driverLoc.geopoint`: `40.7769, -73.8740`

### Driver 4: Fatima Ahmed
- **Document ID**: `fatima.ahmed@driver.com`
- Values:
  - `Car Name`: `Yamaha R15`
  - `Car Plate Num`: `MOT-3456`
  - `Car Type`: `MotorCycle`
  - `name`: `Fatima Ahmed`
  - `email`: `fatima.ahmed@driver.com`
  - `driverStatus`: `Idle`
  - `driverLoc.geopoint`: `39.8719, -75.2411`

## That's it!

After adding all 4 drivers, test your app - they should appear when you click "Request a ride".

