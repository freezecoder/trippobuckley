#!/usr/bin/env python3
"""
Script to add 4 sample drivers to Firestore database.

Install dependencies:
    pip install firebase-admin google-cloud-firestore

Run:
    python3 scripts/add_drivers.py

Or set GOOGLE_APPLICATION_CREDENTIALS environment variable:
    export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
    python3 scripts/add_drivers.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore import GeoPoint
import os

# Initialize Firebase Admin SDK
def initialize_firebase():
    """Initialize Firebase Admin SDK."""
    try:
        # Try to use existing app
        app = firebase_admin.get_app()
        print("✅ Using existing Firebase app")
        return app
    except ValueError:
        # No app exists, initialize it
        print("🔄 Initializing Firebase Admin SDK...")
        
        # Project ID from firebase_options.dart
        PROJECT_ID = "btrips-42089"
        
        # Option 1: Use service account key file (if provided)
        cred_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            app = firebase_admin.initialize_app(cred, {
                'projectId': PROJECT_ID,
            })
            print("✅ Initialized with service account key")
            return app
        
        # Option 2: Try to find service account key in common locations
        possible_paths = [
            'serviceAccountKey.json',
            'btrips_user/serviceAccountKey.json',
            os.path.expanduser('~/Downloads/serviceAccountKey.json'),
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                print(f"📁 Found service account key at: {path}")
                cred = credentials.Certificate(path)
                app = firebase_admin.initialize_app(cred, {
                    'projectId': PROJECT_ID,
                })
                print("✅ Initialized with service account key")
                return app
        
        # Option 3: Use Application Default Credentials (for local development)
        try:
            cred = credentials.ApplicationDefault()
            app = firebase_admin.initialize_app(cred, {
                'projectId': PROJECT_ID,
            })
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
            print("\nOption 3 - Use Firebase Console:")
            print("   Manually add drivers via Firebase Console (see ADD_DRIVERS.md)")
            return None

def add_drivers():
    """Add 4 sample drivers to Firestore."""
    app = initialize_firebase()
    if not app:
        return
    
    db = firestore.client()
    
    # Sample drivers data - Located near major airports in the area
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
    
    print(f"\n📝 Adding {len(drivers)} drivers to Firestore...\n")
    print("-" * 60)
    
    for driver_data in drivers:
        try:
            # Use email as document ID
            doc_ref = db.collection("Drivers").document(driver_data["email"])
            
            # Check if driver already exists
            doc = doc_ref.get()
            if doc.exists:
                print(f"⚠️  Driver {driver_data['email']} already exists. Updating...")
                doc_ref.update(driver_data)
                status = "Updated"
            else:
                doc_ref.set(driver_data)
                status = "Added"
            
            print(f"✅ {status}: {driver_data['name']} ({driver_data['Car Name']})")
            print(f"   📧 Email: {driver_data['email']}")
            print(f"   🚗 Type: {driver_data['Car Type']}")
            print(f"   📍 Location: {driver_data['driverLoc']['geopoint'].latitude}, {driver_data['driverLoc']['geopoint'].longitude}")
            print(f"   🟢 Status: {driver_data['driverStatus']}")
            print("-" * 60)
            
        except Exception as e:
            print(f"❌ Error adding driver {driver_data['email']}: {e}")
            print("-" * 60)
    
    print(f"\n✨ Done! {len(drivers)} drivers processed.")
    print("\n💡 Tip: Check Firebase Console to verify drivers were added.")

if __name__ == "__main__":
    add_drivers()

