#!/usr/bin/env node

/**
 * Script to reset all test rides (delete them)
 * Run with: node scripts/reset_test_rides.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'trippo-42089'
  });
}

const db = admin.firestore();

async function resetRides() {
  console.log('🧹 Resetting all test ride requests...\n');

  try {
    const snapshot = await db.collection('rideRequests').get();

    if (snapshot.empty) {
      console.log('ℹ️  No rides to delete.');
      process.exit(0);
    }

    console.log(`📋 Found ${snapshot.size} ride(s)\n`);

    let count = 0;
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const id = doc.id.substring(0, 8);
      console.log(`🗑️  Deleting ${id}... (status: ${data.status})`);
      await doc.ref.delete();
      count++;
    }

    console.log(`\n✅ Deleted ${count} ride request(s)`);
    console.log('\n🎯 Fresh start! Database is clean.');
    console.log('\n📝 Next steps:');
    console.log('   1. Run: node scripts/simulate_ride_request.js');
    console.log('   2. Login as driver and check Pending tab');
    console.log('   3. Accept ONE ride to test');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }

  process.exit(0);
}

resetRides();

