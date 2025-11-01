#!/usr/bin/env node
/**
 * Simple script to add drivers using Firebase Admin SDK
 * Uses credentials from 'firebase login'
 * 
 * Prerequisites:
 *   npm install firebase-admin
 *   firebase login
 *   firebase use btrips-42089
 * 
 * Run: node scripts/add_drivers_simple.js
 */

const admin = require('firebase-admin');

// Initialize if not already initialized
if (!admin.apps.length) {
  try {
    // Try to use default credentials (from firebase login)
    admin.initializeApp({
      projectId: 'btrips-42089'
    });
    console.log('✅ Initialized Firebase Admin');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase:', error.message);
    console.log('\n💡 Make sure you are logged in:');
    console.log('   firebase login');
    console.log('   firebase use btrips-42089');
    process.exit(1);
  }
}

const db = admin.firestore();

const drivers = [
  {
    email: 'ahmed.khan@driver.com',
    'Car Name': 'Toyota Camry',
    'Car Plate Num': 'ABC-1234',
    'Car Type': 'Car',
    name: 'Ahmed Khan',
    driverStatus: 'Idle',
    rate: 3.0,  // Vehicle rate multiplier
    driverLoc: {
      geopoint: new admin.firestore.GeoPoint(40.6895, -74.1745)
    }
  },
  {
    email: 'sara.ali@driver.com',
    'Car Name': 'Honda Civic',
    'Car Plate Num': 'XYZ-5678',
    'Car Type': 'Car',
    name: 'Sara Ali',
    driverStatus: 'Idle',
    rate: 3.0,  // Vehicle rate multiplier
    driverLoc: {
      geopoint: new admin.firestore.GeoPoint(40.6413, -73.7781)
    }
  },
  {
    email: 'mohammed.hassan@driver.com',
    'Car Name': 'Toyota RAV4',
    'Car Plate Num': 'SUV-9012',
    'Car Type': 'SUV',
    name: 'Mohammed Hassan',
    driverStatus: 'Idle',
    rate: 3.0,  // Vehicle rate multiplier
    driverLoc: {
      geopoint: new admin.firestore.GeoPoint(40.7769, -73.8740)
    }
  },
  {
    email: 'fatima.ahmed@driver.com',
    'Car Name': 'Yamaha R15',
    'Car Plate Num': 'MOT-3456',
    'Car Type': 'MotorCycle',
    name: 'Fatima Ahmed',
    driverStatus: 'Idle',
    rate: 3.0,  // Vehicle rate multiplier
    driverLoc: {
      geopoint: new admin.firestore.GeoPoint(39.8719, -75.2411)
    }
  }
];

async function addDrivers() {
  console.log('🚀 Adding drivers to Firestore...\n');
  console.log('─'.repeat(60));

  for (const driver of drivers) {
    try {
      const docRef = db.collection('Drivers').doc(driver.email);
      const doc = await docRef.get();
      
      if (doc.exists) {
        await docRef.update(driver);
        console.log(`⚠️  Updated: ${driver.name} (${driver['Car Name']})`);
      } else {
        await docRef.set(driver);
        console.log(`✅ Added: ${driver.name} (${driver['Car Name']})`);
      }
      
      console.log(`   📧 ${driver.email}`);
      console.log(`   📍 ${driver.driverLoc.geopoint.latitude}, ${driver.driverLoc.geopoint.longitude}`);
      console.log('─'.repeat(60));
    } catch (error) {
      console.error(`❌ Error: ${driver.email} -`, error.message);
      console.log('─'.repeat(60));
    }
  }

  console.log('\n✨ Done! Check Firebase Console to verify.');
}

addDrivers().catch(console.error);

