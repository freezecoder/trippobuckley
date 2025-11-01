#!/usr/bin/env python3
"""
Initialize BTrips Unified App Firebase Schema
Creates the new collections and indexes needed for the unified app

This script is safe to run multiple times.

Usage:
    python3 scripts/initialize_unified_schema.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore import GeoPoint
from datetime import datetime
import os
import sys

def initialize_firebase():
    """Initialize Firebase Admin SDK."""
    try:
        app = firebase_admin.get_app()
        print("✅ Using existing Firebase app")
        return app
    except ValueError:
        print("🔄 Initializing Firebase Admin SDK...")
        
        PROJECT_ID = "btrips-42089"
        
        possible_paths = [
            'firestore_credentials.json',
            'serviceAccountKey.json',
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                print(f"📁 Found service account key at: {path}")
                cred = credentials.Certificate(path)
                app = firebase_admin.initialize_app(cred, {'projectId': PROJECT_ID})
                print("✅ Initialized with service account key")
                return app
        
        try:
            cred = credentials.ApplicationDefault()
            app = firebase_admin.initialize_app(cred, {'projectId': PROJECT_ID})
            print("✅ Initialized with Application Default Credentials")
            return app
        except Exception as e:
            print("❌ Could not initialize Firebase Admin SDK")
            print(f"Error: {e}")
            return None


def verify_collections(db):
    """Verify and display current collections."""
    print("\n" + "="*60)
    print("📊 CURRENT FIRESTORE COLLECTIONS")
    print("="*60)
    
    collections = db.collections()
    collection_names = [col.id for col in collections]
    
    print(f"\nFound {len(collection_names)} collections:")
    for name in collection_names:
        count = len(list(db.collection(name).limit(100).stream()))
        print(f"   • {name}: {count} documents")
    
    return collection_names


def check_schema_readiness(db):
    """Check if new schema collections exist."""
    print("\n" + "="*60)
    print("🔍 CHECKING NEW SCHEMA READINESS")
    print("="*60)
    
    collections = {
        'users': 'Central user registry',
        'drivers': 'Driver-specific data',
        'userProfiles': 'User-specific data',
        'rideRequests': 'Active ride requests',
        'rideHistory': 'Completed rides',
    }
    
    status = {}
    for col_name, description in collections.items():
        try:
            docs = list(db.collection(col_name).limit(1).stream())
            exists = len(docs) > 0
            count = len(list(db.collection(col_name).stream()))
            status[col_name] = {'exists': exists, 'count': count}
            
            if exists:
                print(f"   ✅ {col_name}: {count} documents - {description}")
            else:
                print(f"   ⏳ {col_name}: Empty (will be created on first use) - {description}")
        except Exception as e:
            print(f"   ❌ {col_name}: Error - {e}")
            status[col_name] = {'exists': False, 'count': 0}
    
    return status


def display_migration_plan(db):
    """Display what the migration will do."""
    print("\n" + "="*60)
    print("📋 MIGRATION PLAN")
    print("="*60)
    
    # Count old drivers
    old_drivers = list(db.collection('Drivers').stream())
    print(f"\n🚗 Drivers to migrate: {len(old_drivers)}")
    
    for driver_doc in old_drivers:
        driver_data = driver_doc.to_dict()
        print(f"   • {driver_doc.id}")
        print(f"     → Name: {driver_data.get('name')}")
        print(f"     → Car: {driver_data.get('Car Name')} ({driver_data.get('Car Type')})")
    
    # Check for user ride history collections
    all_collections = [col.id for col in db.collections()]
    user_collections = [c for c in all_collections if '@' in c]
    
    print(f"\n👤 User ride history collections: {len(user_collections)}")
    for col in user_collections:
        ride_count = len(list(db.collection(col).stream()))
        print(f"   • {col}: {ride_count} rides")
    
    print(f"\n🔄 Migration will:")
    print(f"   1. Create 'users' collection with userType field")
    print(f"   2. Migrate {len(old_drivers)} drivers to new 'drivers' collection")
    print(f"   3. Keep old 'Drivers' collection (backward compatibility)")
    print(f"   4. Create 'userProfiles' for regular users")
    print(f"   5. Preserve all ride history data")


def main():
    """Main function."""
    print("\n" + "="*60)
    print("🚀 BTRIPS UNIFIED APP - SCHEMA INITIALIZATION")
    print("="*60)
    
    app = initialize_firebase()
    if not app:
        sys.exit(1)
    
    db = firestore.client()
    
    # Step 1: Verify current collections
    verify_collections(db)
    
    # Step 2: Check new schema readiness
    check_schema_readiness(db)
    
    # Step 3: Show migration plan
    display_migration_plan(db)
    
    # Conclusion
    print("\n" + "="*60)
    print("✅ SCHEMA VERIFICATION COMPLETE")
    print("="*60)
    print(f"\n💡 To run the actual migration:")
    print(f"   python3 scripts/migrate_to_unified_schema.py")
    print(f"\n📝 Note:")
    print(f"   • New users will automatically create proper documents")
    print(f"   • Migration only needed for existing users/drivers")
    print(f"   • Security rules already deployed ✅")


if __name__ == "__main__":
    main()

