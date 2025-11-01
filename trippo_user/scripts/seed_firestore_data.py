#!/usr/bin/env python3
"""
Comprehensive Firestore data seeding script for BTrips User app.
This script seeds all required collections for testing views.

Install dependencies:
    pip install firebase-admin google-cloud-firestore

Run:
    python3 scripts/seed_firestore_data.py

Or set GOOGLE_APPLICATION_CREDENTIALS environment variable:
    export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
    python3 scripts/seed_firestore_data.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore import GeoPoint
from datetime import datetime, timedelta
import os
import sys

# Initialize Firebase Admin SDK
def initialize_firebase():
    """Initialize Firebase Admin SDK."""
    try:
        app = firebase_admin.get_app()
        print("✅ Using existing Firebase app")
        return app
    except ValueError:
        print("🔄 Initializing Firebase Admin SDK...")
        
        PROJECT_ID = "btrips-42089"
        
        # Option 1: Use service account key file (if provided)
        cred_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            app = firebase_admin.initialize_app(cred, {'projectId': PROJECT_ID})
            print("✅ Initialized with service account key")
            return app
        
        # Option 2: Try to find service account key in common locations
        possible_paths = [
            'firestore_credentials.json',
            'btrips_user/firestore_credentials.json',
            'serviceAccountKey.json',
            'btrips_user/serviceAccountKey.json',
            os.path.expanduser('~/Downloads/serviceAccountKey.json'),
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                print(f"📁 Found service account key at: {path}")
                cred = credentials.Certificate(path)
                app = firebase_admin.initialize_app(cred, {'projectId': PROJECT_ID})
                print("✅ Initialized with service account key")
                return app
        
        # Option 3: Use Application Default Credentials
        try:
            cred = credentials.ApplicationDefault()
            app = firebase_admin.initialize_app(cred, {'projectId': PROJECT_ID})
            print("✅ Initialized with Application Default Credentials")
            return app
        except Exception as e:
            print("❌ Could not initialize Firebase Admin SDK")
            print(f"\nError: {e}")
            print("\n📋 To use this script, you need Firebase credentials:")
            print("\nOption 1 - Download Service Account Key:")
            print("1. Go to: https://console.firebase.google.com/project/btrips-42089/settings/serviceaccounts/adminsdk")
            print("2. Click 'Generate New Private Key'")
            print("3. Save as 'serviceAccountKey.json' in the btrips_user directory")
            print("4. Run the script again")
            print("\nOption 2 - Set Environment Variable:")
            print("   export GOOGLE_APPLICATION_CREDENTIALS='path/to/serviceAccountKey.json'")
            return None

def seed_drivers(db):
    """Seed Drivers collection with sample drivers."""
    print("\n" + "="*60)
    print("🚗 SEEDING DRIVERS COLLECTION")
    print("="*60)
    
    drivers = [
        {
            "Car Name": "Toyota Camry",
            "Car Plate Num": "ABC-1234",
            "Car Type": "Car",
            "name": "Ahmed Khan",
            "email": "ahmed.khan@driver.com",
            "driverStatus": "Idle",
            "rate": 3.0,  # Vehicle rate multiplier
            "driverLoc": {
                "geopoint": GeoPoint(40.6895, -74.1745),  # Near Newark Airport
            },
        },
        {
            "Car Name": "Honda Civic",
            "Car Plate Num": "XYZ-5678",
            "Car Type": "Car",
            "name": "Sara Ali",
            "email": "sara.ali@driver.com",
            "driverStatus": "Idle",
            "rate": 3.0,  # Vehicle rate multiplier
            "driverLoc": {
                "geopoint": GeoPoint(40.6413, -73.7781),  # Near JFK Airport
            },
        },
        {
            "Car Name": "Toyota RAV4",
            "Car Plate Num": "SUV-9012",
            "Car Type": "SUV",
            "name": "Mohammed Hassan",
            "email": "mohammed.hassan@driver.com",
            "driverStatus": "Idle",
            "rate": 3.0,  # Vehicle rate multiplier
            "driverLoc": {
                "geopoint": GeoPoint(40.7769, -73.8740),  # Near La Guardia Airport
            },
        },
        {
            "Car Name": "Yamaha R15",
            "Car Plate Num": "MOT-3456",
            "Car Type": "MotorCycle",
            "name": "Fatima Ahmed",
            "email": "fatima.ahmed@driver.com",
            "driverStatus": "Idle",
            "rate": 3.0,  # Vehicle rate multiplier
            "driverLoc": {
                "geopoint": GeoPoint(39.8719, -75.2411),  # Near Philadelphia Airport
            },
        },
    ]
    
    added_count = 0
    updated_count = 0
    
    for driver_data in drivers:
        try:
            doc_ref = db.collection("Drivers").document(driver_data["email"])
            doc = doc_ref.get()
            
            if doc.exists:
                doc_ref.update(driver_data)
                status = "Updated"
                updated_count += 1
            else:
                doc_ref.set(driver_data)
                status = "Added"
                added_count += 1
            
            print(f"✅ {status}: {driver_data['name']} ({driver_data['Car Name']})")
            print(f"   📧 {driver_data['email']}")
            print(f"   🚗 Type: {driver_data['Car Type']}")
            print(f"   📍 {driver_data['driverLoc']['geopoint'].latitude}, {driver_data['driverLoc']['geopoint'].longitude}")
            print(f"   🟢 Status: {driver_data['driverStatus']}")
            
        except Exception as e:
            print(f"❌ Error with driver {driver_data['email']}: {e}")
    
    print(f"\n📊 Drivers: {added_count} added, {updated_count} updated")
    return len(drivers)

def seed_test_user_rides(db, test_user_email="test.user@example.com"):
    """Seed test user ride requests collection.
    
    Args:
        db: Firestore client
        test_user_email: Email of test user (collection name)
    """
    print("\n" + "="*60)
    print(f"🚕 SEEDING USER RIDE REQUESTS ({test_user_email})")
    print("="*60)
    
    # Sample ride requests - these simulate past ride history
    ride_requests = [
        {
            "OriginLat": 40.6895,
            "OriginLng": -74.1745,
            "OriginAddress": "Newark Liberty International Airport",
            "destinationLat": 40.7589,
            "destinationLng": -73.9851,
            "destinationAddress": "Times Square, New York, NY",
            "time": datetime.now() - timedelta(days=3),
            "userEmail": test_user_email,
            "driverEmail": "ahmed.khan@driver.com"
        },
        {
            "OriginLat": 40.6413,
            "OriginLng": -73.7781,
            "OriginAddress": "John F. Kennedy International Airport",
            "destinationLat": 40.7128,
            "destinationLng": -74.0060,
            "destinationAddress": "Central Park, New York, NY",
            "time": datetime.now() - timedelta(days=2),
            "userEmail": test_user_email,
            "driverEmail": "sara.ali@driver.com"
        },
        {
            "OriginLat": 40.7769,
            "OriginLng": -73.8740,
            "OriginAddress": "LaGuardia Airport",
            "destinationLat": 40.7484,
            "destinationLng": -73.9857,
            "destinationAddress": "Empire State Building, New York, NY",
            "time": datetime.now() - timedelta(days=1),
            "userEmail": test_user_email,
            "driverEmail": "mohammed.hassan@driver.com"
        },
        {
            "OriginLat": 39.8719,
            "OriginLng": -75.2411,
            "OriginAddress": "Philadelphia International Airport",
            "destinationLat": 40.7488,
            "destinationLng": -73.9680,
            "destinationAddress": "Brooklyn Bridge, New York, NY",
            "time": datetime.now() - timedelta(hours=12),
            "userEmail": test_user_email,
            "driverEmail": "fatima.ahmed@driver.com"
        },
    ]
    
    added_count = 0
    
    # Clear existing rides for this user first
    try:
        existing_rides = db.collection(test_user_email).get()
        for ride in existing_rides:
            ride.reference.delete()
        if existing_rides:
            print(f"🗑️  Cleared {len(existing_rides)} existing ride(s)")
    except Exception as e:
        print(f"⚠️  Could not clear existing rides: {e}")
    
    # Add new ride requests
    for ride_data in ride_requests:
        try:
            doc_ref = db.collection(test_user_email).add(ride_data)
            added_count += 1
            print(f"✅ Added ride: {ride_data['OriginAddress']} → {ride_data['destinationAddress']}")
            print(f"   🕐 Time: {ride_data['time'].strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"   👤 Driver: {ride_data['driverEmail']}")
        except Exception as e:
            print(f"❌ Error adding ride: {e}")
    
    print(f"\n📊 Ride Requests: {added_count} added")
    return added_count

def main():
    """Main seeding function."""
    print("\n" + "="*60)
    print("🌱 BTRIPS FIRESTORE DATA SEEDING")
    print("="*60)
    
    app = initialize_firebase()
    if not app:
        sys.exit(1)
    
    db = firestore.client()
    
    # Seed drivers
    drivers_count = seed_drivers(db)
    
    # Seed test user rides (optional - only if test user email provided)
    test_user_email = os.environ.get('TEST_USER_EMAIL', 'test.user@example.com')
    if test_user_email:
        rides_count = seed_test_user_rides(db, test_user_email)
    else:
        rides_count = 0
        print("\n⚠️  Skipping user rides (set TEST_USER_EMAIL env var to seed)")
    
    # Summary
    print("\n" + "="*60)
    print("✨ SEEDING COMPLETE")
    print("="*60)
    print(f"📊 Summary:")
    print(f"   🚗 Drivers: {drivers_count} processed")
    if rides_count > 0:
        print(f"   🚕 Ride Requests: {rides_count} added")
    print("\n💡 Tip: Check Firebase Console to verify data was added.")
    print("\n📝 Note: For ride history testing, create a user with email:")
    print(f"   {test_user_email}")
    print("   Or change TEST_USER_EMAIL env var to match your test user.")

if __name__ == "__main__":
    main()

