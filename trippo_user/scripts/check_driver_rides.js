#!/usr/bin/env node

/**
 * Script to check what rides are assigned to a specific driver
 * Run with: node scripts/check_driver_rides.js <driver-email>
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
const auth = admin.auth();

async function checkDriverRides(driverEmail) {
  console.log(`🔍 Checking rides for driver: ${driverEmail}\n`);

  try {
    // Get driver's UID
    const driverAuth = await auth.getUserByEmail(driverEmail);
    const driverId = driverAuth.uid;
    console.log(`✅ Found driver with UID: ${driverId}\n`);

    // Get all ride requests
    const allRides = await db.collection('rideRequests').get();
    console.log(`📋 Total rides in database: ${allRides.size}\n`);

    // Filter by driver
    let pendingCount = 0;
    let acceptedCount = 0;
    let ongoingCount = 0;
    let completedCount = 0;

    console.log('📊 Rides assigned to this driver:\n');
    console.log('ID           | Status    | Pickup → Dropoff');
    console.log('─'.repeat(70));

    const driverRides = [];
    
    for (const doc of allRides.docs) {
      const data = doc.data();
      
      if (data.driverId === driverId) {
        const id = doc.id.substring(0, 8);
        const status = data.status || 'unknown';
        const pickup = (data.pickupAddress || 'unknown').substring(0, 25);
        const dropoff = (data.dropoffAddress || 'unknown').substring(0, 25);

        console.log(`${id}... | ${status.padEnd(9)} | ${pickup} → ${dropoff}`);
        driverRides.push({ id: doc.id, status, data });

        switch (status) {
          case 'pending': pendingCount++; break;
          case 'accepted': acceptedCount++; break;
          case 'ongoing': ongoingCount++; break;
          case 'completed': completedCount++; break;
        }
      }
    }

    if (driverRides.length === 0) {
      console.log('(No rides assigned to this driver)');
    }

    console.log('\n📊 Summary:');
    console.log(`   Pending:   ${pendingCount}`);
    console.log(`   Accepted:  ${acceptedCount} ⭐ (Should show in Active tab)`);
    console.log(`   Ongoing:   ${ongoingCount} ⭐ (Should show in Active tab)`);
    console.log(`   Completed: ${completedCount} (Should show in History tab)`);

    // Show all pending rides (not assigned to anyone)
    console.log('\n📋 All pending rides (not assigned):');
    console.log('─'.repeat(70));
    
    let unassignedPending = 0;
    for (const doc of allRides.docs) {
      const data = doc.data();
      if (data.status === 'pending' && !data.driverId) {
        const id = doc.id.substring(0, 8);
        const fare = data.fare ? `$${data.fare.toFixed(2)}` : 'unknown';
        const pickup = (data.pickupAddress || 'unknown').substring(0, 25);
        console.log(`${id}... | ${fare.padEnd(7)} | ${pickup}`);
        unassignedPending++;
      }
    }
    
    if (unassignedPending === 0) {
      console.log('(No unassigned pending rides)');
    }

    console.log('\n═══════════════════════════════════════');
    console.log('🎯 EXPECTED IN APP:');
    console.log('═══════════════════════════════════════');
    console.log(`Pending Tab:  ${unassignedPending} ride(s)`);
    console.log(`Active Tab:   ${acceptedCount + ongoingCount} ride(s)`);
    console.log(`History Tab:  ${completedCount} ride(s)`);

    // Show detailed ride info for accepted/ongoing
    if (acceptedCount + ongoingCount > 0) {
      console.log('\n📋 Detailed Active Rides:');
      for (const ride of driverRides) {
        if (ride.status === 'accepted' || ride.status === 'ongoing') {
          console.log(`\nRide ID: ${ride.id}`);
          console.log(`  Status: ${ride.status}`);
          console.log(`  Pickup: ${ride.data.pickupAddress}`);
          console.log(`  Dropoff: ${ride.data.dropoffAddress}`);
          console.log(`  Fare: $${ride.data.fare?.toFixed(2) || '0.00'}`);
          console.log(`  Accepted At: ${ride.data.acceptedAt?.toDate() || 'N/A'}`);
        }
      }
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }

  process.exit(0);
}

// Get driver email from command line
const driverEmail = process.argv[2] || 'driver@bt.com';
checkDriverRides(driverEmail);

