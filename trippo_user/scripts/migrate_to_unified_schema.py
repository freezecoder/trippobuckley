#!/usr/bin/env python3
"""
Migration script for BTrips Unified App
Migrates existing Firebase data to new unified schema

This script:
1. Creates 'users' collection with userType field for existing accounts
2. Migrates drivers from 'Drivers' collection to new 'drivers' and 'users' collections
3. Creates 'userProfiles' collection for existing users
4. Preserves all existing data

Usage:
    python3 scripts/migrate_to_unified_schema.py

Requirements:
    pip install firebase-admin google-cloud-firestore
"""

import firebase_admin
from firebase_admin import credentials, firestore, auth
from datetime import datetime
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
        
        # Try to find service account key
        possible_paths = [
            'firestore_credentials.json',
            'serviceAccountKey.json',
            os.path.expanduser('~/Downloads/serviceAccountKey.json'),
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                print(f"📁 Found service account key at: {path}")
                cred = credentials.Certificate(path)
                app = firebase_admin.initialize_app(cred, {'projectId': PROJECT_ID})
                print("✅ Initialized with service account key")
                return app
        
        # Try Application Default Credentials
        try:
            cred = credentials.ApplicationDefault()
            app = firebase_admin.initialize_app(cred, {'projectId': PROJECT_ID})
            print("✅ Initialized with Application Default Credentials")
            return app
        except Exception as e:
            print("❌ Could not initialize Firebase Admin SDK")
            print(f"Error: {e}")
            return None


def migrate_drivers_to_new_schema(db):
    """Migrate drivers from old 'Drivers' collection to new schema."""
    print("\n" + "="*60)
    print("🚗 MIGRATING DRIVERS TO NEW SCHEMA")
    print("="*60)
    
    try:
        # Get all documents from old 'Drivers' collection
        old_drivers = db.collection('Drivers').stream()
        
        migrated_count = 0
        skipped_count = 0
        
        for driver_doc in old_drivers:
            driver_data = driver_doc.to_dict()
            driver_email = driver_doc.id  # Old collection used email as ID
            
            print(f"\n📧 Processing: {driver_email}")
            
            # Try to find Firebase Auth user by email
            try:
                firebase_user = auth.get_user_by_email(driver_email)
                user_uid = firebase_user.uid
                print(f"   ✓ Found Firebase Auth user: {user_uid}")
            except auth.UserNotFoundError:
                print(f"   ⚠️  No Firebase Auth user found for {driver_email}")
                print(f"   → Skipping (driver needs to register via app)")
                skipped_count += 1
                continue
            
            # Create/update user document in 'users' collection
            user_doc_ref = db.collection('users').document(user_uid)
            user_doc = user_doc_ref.get()
            
            if not user_doc.exists:
                # Create new user document
                user_data = {
                    'email': driver_email,
                    'name': driver_data.get('name', 'Driver'),
                    'userType': 'driver',
                    'phoneNumber': '',
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'lastLogin': firestore.SERVER_TIMESTAMP,
                    'isActive': True,
                    'fcmToken': '',
                    'profileImageUrl': '',
                }
                user_doc_ref.set(user_data)
                print(f"   ✓ Created users/{user_uid}")
            else:
                # Update existing user with userType
                user_doc_ref.update({'userType': 'driver'})
                print(f"   ✓ Updated users/{user_uid} with userType: 'driver'")
            
            # Create/update driver document in 'drivers' collection
            driver_doc_ref = db.collection('drivers').document(user_uid)
            
            # Prepare driver data for new schema
            new_driver_data = {
                'carName': driver_data.get('Car Name', ''),
                'carPlateNum': driver_data.get('Car Plate Num', ''),
                'carType': driver_data.get('Car Type', 'Car'),
                'rate': driver_data.get('rate', 3.0),
                'driverStatus': driver_data.get('driverStatus', 'Offline'),
                'rating': 5.0,  # Default rating
                'totalRides': 0,  # Default
                'earnings': 0.0,  # Default
                'licenseNumber': '',
                'vehicleRegistration': '',
                'isVerified': False,
            }
            
            # Migrate location if exists
            if 'driverLoc' in driver_data:
                new_driver_data['driverLoc'] = driver_data['driverLoc']
                
            driver_doc_ref.set(new_driver_data)
            print(f"   ✓ Created drivers/{user_uid}")
            print(f"   → Car: {new_driver_data['carName']} ({new_driver_data['carType']})")
            
            migrated_count += 1
        
        print(f"\n📊 Migration Summary:")
        print(f"   ✅ Migrated: {migrated_count} drivers")
        print(f"   ⚠️  Skipped: {skipped_count} (no Auth account)")
        
        return migrated_count
        
    except Exception as e:
        print(f"❌ Error migrating drivers: {e}")
        return 0


def create_user_profiles_for_existing_users(db):
    """Create userProfiles for existing users who don't have driver data."""
    print("\n" + "="*60)
    print("👤 CREATING USER PROFILES FOR EXISTING USERS")
    print("="*60)
    
    try:
        # This will create userProfiles for any existing Firebase Auth users
        # who aren't drivers
        
        # Get all users from 'users' collection
        users = db.collection('users').stream()
        
        created_count = 0
        
        for user_doc in users:
            user_data = user_doc.to_dict()
            user_id = user_doc.id
            user_type = user_data.get('userType', 'user')
            
            # Only create profiles for regular users
            if user_type == 'user':
                profile_ref = db.collection('userProfiles').document(user_id)
                profile_doc = profile_ref.get()
                
                if not profile_doc.exists:
                    profile_data = {
                        'homeAddress': '',
                        'workAddress': '',
                        'favoriteLocations': [],
                        'paymentMethods': [],
                        'preferences': {
                            'notifications': True,
                            'language': 'en',
                            'theme': 'dark',
                        },
                        'totalRides': 0,
                        'rating': 5.0,
                    }
                    profile_ref.set(profile_data)
                    print(f"   ✓ Created userProfiles/{user_id}")
                    created_count += 1
        
        print(f"\n📊 Created {created_count} user profiles")
        return created_count
        
    except Exception as e:
        print(f"❌ Error creating user profiles: {e}")
        return 0


def verify_migration(db):
    """Verify the migration was successful."""
    print("\n" + "="*60)
    print("🔍 VERIFYING MIGRATION")
    print("="*60)
    
    try:
        # Count documents in each collection
        users_count = len(list(db.collection('users').stream()))
        drivers_count = len(list(db.collection('drivers').stream()))
        profiles_count = len(list(db.collection('userProfiles').stream()))
        old_drivers_count = len(list(db.collection('Drivers').stream()))
        
        print(f"\n📊 Collection Counts:")
        print(f"   users: {users_count}")
        print(f"   drivers: {drivers_count}")
        print(f"   userProfiles: {profiles_count}")
        print(f"   Drivers (old): {old_drivers_count}")
        
        # Show sample data
        print(f"\n📋 Sample Data:")
        
        # Show a user
        users = list(db.collection('users').limit(1).stream())
        if users:
            user = users[0]
            print(f"\n   users/{user.id}:")
            print(f"      userType: {user.to_dict().get('userType')}")
            print(f"      email: {user.to_dict().get('email')}")
        
        # Show a driver
        drivers = list(db.collection('drivers').limit(1).stream())
        if drivers:
            driver = drivers[0]
            print(f"\n   drivers/{driver.id}:")
            print(f"      carName: {driver.to_dict().get('carName')}")
            print(f"      driverStatus: {driver.to_dict().get('driverStatus')}")
        
        print(f"\n✅ Migration verification complete!")
        
    except Exception as e:
        print(f"❌ Error verifying migration: {e}")


def main():
    """Main migration function."""
    print("\n" + "="*60)
    print("🔄 BTRIPS UNIFIED APP - FIREBASE MIGRATION")
    print("="*60)
    print("\nThis script migrates from old schema to new unified schema:")
    print("  • Drivers collection → drivers + users")
    print("  • Creates users collection with userType field")
    print("  • Creates userProfiles for regular users")
    print("\n⚠️  WARNING: This will modify your Firebase database!")
    
    # Confirmation
    response = input("\nProceed with migration? (yes/no): ")
    if response.lower() != 'yes':
        print("❌ Migration cancelled")
        return
    
    app = initialize_firebase()
    if not app:
        sys.exit(1)
    
    db = firestore.client()
    
    # Step 1: Migrate drivers
    print("\n📍 Step 1: Migrating drivers...")
    drivers_migrated = migrate_drivers_to_new_schema(db)
    
    # Step 2: Create user profiles
    print("\n📍 Step 2: Creating user profiles...")
    profiles_created = create_user_profiles_for_existing_users(db)
    
    # Step 3: Verify
    print("\n📍 Step 3: Verifying migration...")
    verify_migration(db)
    
    # Summary
    print("\n" + "="*60)
    print("✨ MIGRATION COMPLETE")
    print("="*60)
    print(f"\n📊 Summary:")
    print(f"   🚗 Drivers migrated: {drivers_migrated}")
    print(f"   👤 User profiles created: {profiles_created}")
    print(f"\n💡 Next Steps:")
    print(f"   1. Verify data in Firebase Console")
    print(f"   2. Test app with existing accounts")
    print(f"   3. Register new test users/drivers")
    print(f"\n🔗 Firebase Console:")
    print(f"   https://console.firebase.google.com/project/btrips-42089/firestore")


if __name__ == "__main__":
    main()

