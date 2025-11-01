#!/usr/bin/env node

/**
 * Script to check pending ride requests in Firestore
 * Helps diagnose why driver can't see pending rides
 * Run with: node scripts/check_pending_rides.js
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

async function checkPendingRides() {
  console.log('🔍 Checking pending ride requests...\n');

  try {
    // Get ALL ride requests (no filters)
    console.log('📋 Step 1: Fetching all ride requests...');
    const allRides = await db.collection('rideRequests').get();

    if (allRides.empty) {
      console.log('❌ NO ride requests found in database!');
      console.log('   Run: node scripts/simulate_ride_request.js');
      process.exit(0);
    }

    console.log(`✅ Found ${allRides.size} total ride request(s)\n`);

    // Analyze each ride
    let pendingCount = 0;
    let acceptedCount = 0;
    let ongoingCount = 0;
    let completedCount = 0;
    let otherCount = 0;

    console.log('📊 Ride Requests:\n');
    console.log('ID           | Status    | Driver       | Pickup → Dropoff');
    console.log('─'.repeat(75));

    for (const doc of allRides.docs) {
      const data = doc.data();
      const id = doc.id.substring(0, 8);
      const status = data.status || 'unknown';
      const driver = data.driverEmail || 'none';
      const pickup = (data.pickupAddress || 'unknown').substring(0, 20);
      const dropoff = (data.dropoffAddress || 'unknown').substring(0, 20);

      console.log(`${id}... | ${status.padEnd(9)} | ${driver.padEnd(12)} | ${pickup} → ${dropoff}`);

      // Count by status
      switch (status) {
        case 'pending':
          pendingCount++;
          break;
        case 'accepted':
          acceptedCount++;
          break;
        case 'ongoing':
          ongoingCount++;
          break;
        case 'completed':
          completedCount++;
          break;
        default:
          otherCount++;
      }
    }

    console.log('\n📊 Summary by Status:');
    console.log(`   Pending:   ${pendingCount} ⭐ (These should show in Pending tab)`);
    console.log(`   Accepted:  ${acceptedCount}`);
    console.log(`   Ongoing:   ${ongoingCount}`);
    console.log(`   Completed: ${completedCount}`);
    if (otherCount > 0) {
      console.log(`   Other:     ${otherCount}`);
    }

    // Now try the same query the app uses
    console.log('\n📋 Step 2: Testing app query (status = pending)...');
    try {
      const pendingRides = await db.collection('rideRequests')
        .where('status', '==', 'pending')
        .orderBy('requestedAt', 'desc')
        .limit(10)
        .get();

      console.log(`✅ Query successful! Found ${pendingRides.size} pending ride(s)`);
      
      if (pendingRides.size === 0 && pendingCount > 0) {
        console.log('\n⚠️  WARNING: Found pending rides in Step 1, but query returned 0!');
        console.log('   This means the index might need time to build.');
      }

    } catch (error) {
      console.log('❌ Query FAILED with error:');
      console.log(`   ${error.message}`);
      
      if (error.message.includes('index')) {
        console.log('\n🔧 SOLUTION: Missing Firestore index!');
        console.log('   The query requires a composite index on (status, requestedAt)');
        console.log('\n   Option 1: Click the link in the error message');
        console.log('   Option 2: Wait for the first document to trigger auto-index creation');
        console.log('   Option 3: Create index manually in Firebase Console\n');
        console.log('📝 Manual Index Setup:');
        console.log('   1. Go to: https://console.firebase.google.com/project/trippo-42089/firestore/indexes');
        console.log('   2. Click "Add Index"');
        console.log('   3. Collection: rideRequests');
        console.log('   4. Fields:');
        console.log('      - status (Ascending)');
        console.log('      - requestedAt (Descending)');
        console.log('   5. Click "Create Index"');
        console.log('   6. Wait 2-5 minutes for index to build');
      }
    }

    // Check if rides have required fields
    console.log('\n📋 Step 3: Validating ride request structure...');
    let missingFields = false;
    
    for (const doc of allRides.docs) {
      const data = doc.data();
      const required = ['userId', 'status', 'pickupLocation', 'dropoffLocation', 'fare'];
      const missing = required.filter(field => !data[field]);
      
      if (missing.length > 0) {
        console.log(`⚠️  Ride ${doc.id.substring(0, 8)}... missing fields: ${missing.join(', ')}`);
        missingFields = true;
      }
    }

    if (!missingFields) {
      console.log('✅ All rides have required fields');
    }

    console.log('\n═══════════════════════════════════════');
    console.log('🎯 NEXT STEPS:');
    console.log('═══════════════════════════════════════');
    
    if (pendingCount === 0) {
      console.log('1. Create test rides: node scripts/simulate_ride_request.js');
    } else {
      console.log(`1. ${pendingCount} pending ride(s) found ✅`);
    }
    
    console.log('2. Open driver app');
    console.log('3. Login as: driver@bt.com / Test123!');
    console.log('4. Go to Rides → Pending tab');
    console.log('5. Pull down to refresh');
    console.log('6. Check Flutter console for errors\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }

  process.exit(0);
}

checkPendingRides();

