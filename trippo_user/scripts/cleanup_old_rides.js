#!/usr/bin/env node

/**
 * Script to clean up old/invalid ride requests
 * Removes rides with assigned drivers or old pending rides
 * Run with: node scripts/cleanup_old_rides.js
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

async function cleanupRides() {
  console.log('🧹 Cleaning up old ride requests...\n');

  try {
    // Get all ride requests
    const snapshot = await db.collection('rideRequests').get();

    if (snapshot.empty) {
      console.log('ℹ️  No ride requests found.');
      process.exit(0);
    }

    console.log(`📋 Found ${snapshot.size} ride request(s)\n`);

    let deletedCount = 0;
    let keptCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const rideId = doc.id;

      // Check if ride has issues
      const hasOldDriver = data.driverEmail && data.driverEmail !== 'driver@bt.com' && data.status === 'pending';
      const isOld = data.requestedAt && 
        (new Date() - data.requestedAt.toDate()) > 24 * 60 * 60 * 1000; // Older than 24 hours

      if (hasOldDriver) {
        console.log(`🗑️  Deleting ride ${rideId.substring(0, 8)}... (assigned to ${data.driverEmail})`);
        await doc.ref.delete();
        deletedCount++;
      } else if (isOld && data.status === 'pending') {
        console.log(`🗑️  Deleting old ride ${rideId.substring(0, 8)}... (${Math.floor((new Date() - data.requestedAt.toDate()) / (60 * 60 * 1000))} hours old)`);
        await doc.ref.delete();
        deletedCount++;
      } else {
        console.log(`✅ Keeping ride ${rideId.substring(0, 8)} (status: ${data.status}, driver: ${data.driverEmail || 'none'})`);
        keptCount++;
      }
    }

    console.log(`\n✅ Cleanup complete!`);
    console.log(`   Deleted: ${deletedCount}`);
    console.log(`   Kept: ${keptCount}`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }

  process.exit(0);
}

cleanupRides();

