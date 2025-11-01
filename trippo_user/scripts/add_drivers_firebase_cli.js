#!/usr/bin/env node
/**
 * Script to add 4 drivers to Firestore using Firebase Admin SDK
 * Works with Firebase CLI authentication (firebase login)
 * 
 * Prerequisites:
 *   firebase login
 *   firebase use btrips-42089
 * 
 * Run: node scripts/add_drivers_firebase_cli.js
 */

const admin = require('firebase-admin');
const { initializeApp } = require('firebase/app');
const { getFirestore } = require('firebase/firestore');

// Try to use Firebase CLI credentials
const { execSync } = require('child_process');

// Get project ID
const PROJECT_ID = 'btrips-42089';

// Drivers data
const drivers = [
  {
    email: 'ahmed.khan@driver.com',
    name: 'Ahmed Khan',
    carName: 'Toyota Camry',
    plateNum: 'ABC-1234',
    carType: 'Car',
    status: 'Idle',
    location: { lat: 40.6895, lng: -74.1745 }
  },
  {
    email: 'sara.ali@driver.com',
    name: 'Sara Ali',
    carName: 'Honda Civic',
    plateNum: 'XYZ-5678',
    carType: 'Car',
    status: 'Idle',
    location: { lat: 40.6413, lng: -73.7781 }
  },
  {
    email: 'mohammed.hassan@driver.com',
    name: 'Mohammed Hassan',
    carName: 'Toyota RAV4',
    plateNum: 'SUV-9012',
    carType: 'SUV',
    status: 'Idle',
    location: { lat: 40.7769, lng: -73.8740 }
  },
  {
    email: 'fatima.ahmed@driver.com',
    name: 'Fatima Ahmed',
    carName: 'Yamaha R15',
    plateNum: 'MOT-3456',
    carType: 'MotorCycle',
    status: 'Idle',
    location: { lat: 39.8719, lng: -75.2411 }
  }
];

async function addDrivers() {
  try {
    // Try to initialize with default credentials (from firebase login)
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: PROJECT_ID,
        credential: admin.credential.applicationDefault()
      });
    }

    const db = admin.firestore();
    
    console.log(`🚀 Adding ${drivers.length} drivers to Firestore...\n`);
    console.log('─'.repeat(60));

    for (const driver of drivers) {
      try {
        const docRef = db.collection('Drivers').doc(driver.email);
        
        const driverData = {
          'Car Name': driver.carName,
          'Car Plate Num': driver.plateNum,
          'Car Type': driver.carType,
          name: driver.name,
          email: driver.email,
          driverStatus: driver.status,
          driverLoc: {
            geopoint: new admin.firestore.GeoPoint(
              driver.location.lat,
              driver.location.lng
            )
          }
        };

        const doc = await docRef.get();
        if (doc.exists) {
          await docRef.update(driverData);
          console.log(`⚠️  Updated: ${driver.name} (${driver.carName})`);
        } else {
          await docRef.set(driverData);
          console.log(`✅ Added: ${driver.name} (${driver.carName})`);
        }
        
        console.log(`   📧 ${driver.email}`);
        console.log(`   📍 ${driver.location.lat}, ${driver.location.lng}`);
        console.log('─'.repeat(60));
      } catch (error) {
        console.error(`❌ Error adding ${driver.email}:`, error.message);
        console.log('─'.repeat(60));
      }
    }

    console.log(`\n✨ Done! ${drivers.length} drivers processed.`);
    console.log(`\n💡 Verify: https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.log('\n📋 Setup instructions:');
    console.log('1. Install Firebase CLI: npm install -g firebase-tools');
    console.log('2. Login: firebase login');
    console.log('3. Set project: firebase use btrips-42089');
    console.log('4. Install Node dependencies: npm install firebase-admin');
    console.log('5. Run script again');
    process.exit(1);
  }
}

addDrivers();

